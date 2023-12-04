module CouchbaseOrm
    module Relation
        extend ActiveSupport::Concern

        class CouchbaseOrm_Relation
            def initialize(model:, where: where = nil, order: order = nil, limit: limit = nil, _not: _not = false, strict_loading: strict_loading = false)
                CouchbaseOrm::logger.debug "CouchbaseOrm_Relation init: #{model} where:#{where.inspect} not:#{_not.inspect} order:#{order.inspect} limit: #{limit} strict_loading: #{strict_loading}"
                @model = model
                @limit = limit
                @where = []
                @order = {}
                @order = merge_order(**order) if order
                @where = merge_where(where, _not) if where
                @strict_loading = strict_loading
                CouchbaseOrm::logger.debug "- #{to_s}"
            end

            def to_s
                "CouchbaseOrm_Relation: #{@model} where:#{@where.inspect} order:#{@order.inspect} limit: #{@limit} strict_loading: #{@strict_loading}"
            end

            def to_n1ql
                bucket_name = @model.bucket.name
                where = build_where
                order = build_order
                limit = build_limit
                "select raw meta().id from `#{bucket_name}` where #{where} order by #{order} #{limit}"
            end

            def execute(n1ql_query)
                result = @model.cluster.query(n1ql_query, Couchbase::Options::Query.new(scan_consistency: CouchbaseOrm::N1ql.config[:scan_consistency]))
                CouchbaseOrm.logger.debug { "Relation query: #{n1ql_query} return #{result.rows.to_a.length} rows with scan_consistency : #{CouchbaseOrm::N1ql.config[:scan_consistency]}" }
                N1qlProxy.new(result)
            end

            def query
                CouchbaseOrm::logger.debug("Query: #{self}")
                n1ql_query = to_n1ql
                execute(n1ql_query)
            end
            
            def update_all(**cond)
                bucket_name = @model.bucket.name
                where = build_where
                limit = build_limit
                update = build_update(**cond)
                n1ql_query = "update `#{bucket_name}` set #{update} where #{where} #{limit}"
                execute(n1ql_query)
            end

            def ids
                query.to_a
            end

            def strict_loading
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(strict_loading: true))
            end

            def strict_loading?
                !!@strict_loading
            end

            def first
                result = @model.cluster.query(self.limit(1).to_n1ql, Couchbase::Options::Query.new(scan_consistency: CouchbaseOrm::N1ql.config[:scan_consistency]))
                return unless (first_id = result.rows.to_a.first)

                @model.find(first_id, with_strict_loading: @strict_loading)
            end

            def last
                result = @model.cluster.query(to_n1ql, Couchbase::Options::Query.new(scan_consistency: CouchbaseOrm::N1ql.config[:scan_consistency]))
                last_id = result.rows.to_a.last
                @model.find(last_id, with_strict_loading: @strict_loading) if last_id
            end

            def count
                query.count
            end

            def empty?
                limit(1).count == 0
            end

            def pluck(*fields)
                map do |model|
                    if fields.length == 1
                        model.send(fields.first)
                    else
                        fields.map do |field|
                            model.send(field)
                        end
                    end
                end
            end

            alias :size :count
            alias :length :count

            def to_ary
                ids = query.results
                return [] if ids.empty?
                Array(ids && @model.find(ids, with_strict_loading: @strict_loading))
            end

            alias :to_a :to_ary

            delegate :each, :map, :collect, :find, :filter, :reduce, :to => :to_ary

            def [](*args)
                to_ary[*args]
            end

            def delete_all
                CouchbaseOrm::logger.debug{ "Delete all: #{self}" }
                ids = query.to_a
                CouchbaseOrm::Connection.bucket.default_collection.remove_multi(ids) unless ids.empty?
            end

            def where(string_cond=nil, **conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: merge_where(conds)+string_where(string_cond)))
            end

            def find_by(**conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: merge_where(conds))).first
            end

            def not(**conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: merge_where(conds, _not: true)))
            end

            def order(*lorder, **horder)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(order: merge_order(*lorder, **horder)))
            end

            def limit(limit)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(limit: limit))
            end

            def all
                CouchbaseOrm_Relation.new(**initializer_arguments)
            end

            def scoping
                scopes = (Thread.current[@model.name] ||= [])
                scopes.push(self)
                result = yield
            ensure
                scopes.pop
                result
            end

            private

            def build_limit
                @limit ? "limit #{@limit}" : ""
            end

            def initializer_arguments
                { model: @model, order: @order, where: @where, limit: @limit, strict_loading: @strict_loading }
            end

            def merge_order(*lorder, **horder)
                raise ArgumentError, "invalid order passed by list: #{lorder.inspect}, must be symbols" unless lorder.all? { |o| o.is_a? Symbol }
                raise ArgumentError, "Invalid order passed by hash: #{horder.inspect}, must be symbol -> :asc|:desc" unless horder.all? { |k, v| k.is_a?(Symbol) && [:asc, :desc].include?(v) }
                @order
                    .merge(Array.wrap(lorder).map{ |o| [o, :asc] }.to_h)
                    .merge(horder)
            end
     
            def merge_where(conds, _not = false)
                @where + (_not ? conds.to_a.map{|k,v|[k,v,:not]} : conds.to_a)
            end

            def string_where(string_cond, _not = false)
                return [] unless string_cond
                cond = "(#{string_cond})"
                [(_not ? [nil, cond, :not] : [nil, cond])]
            end

            def build_order
                order = @order.map do |key, value|
                    "#{key} #{value}"
                end.join(", ")
                order.empty? ? "meta().id" : order
            end
            
            def build_where
                build_conds([[:type, @model.design_document]] + @where)
            end

            def build_conds(conds)
                conds.map do |key, value, opt|
                    if key
                        opt == :not ? 
                            @model.build_not_match(key, value) : 
                            @model.build_match(key, value)
                    else
                        value
                    end
                end.join(" AND ")
            end

            def build_update(**cond)
                cond.map do |key, value|
                    for_clause=""
                    if value.is_a?(Hash) && value[:_for]
                        path_clause = value.delete(:_for)
                        var_clause = path_clause.to_s.split(".").last.singularize
                        
                        _when = value.delete(:_when)
                        when_clause = _when ? build_conds(_when.to_a) : ""
                        
                        _set = value.delete(:_set)                       
                        value = _set if _set

                        for_clause = " for #{var_clause} in #{path_clause} when #{when_clause} end"
                    end
                    if value.is_a?(Hash)
                        value.map do |k, v|
                            "#{key}.#{k} = #{v}"
                        end.join(", ") + for_clause
                    else
                        "#{key} = #{@model.quote(value)}#{for_clause}"
                    end
                end.join(", ")
            end

            def method_missing(method, *args, &block)
                if @model.respond_to?(method)
                    scoping {
                        @model.public_send(method, *args, &block)
                    }
                else
                    super
                end
            end
        end

        module ClassMethods
            def relation
                Thread.current[self.name]&.last || CouchbaseOrm_Relation.new(model: self)
            end

            delegate :ids, :update_all, :delete_all, :count, :empty?, :filter, :reduce, :find_by, to: :all

            delegate :where, :not, :order, :limit, :all, :strict_loading, :strict_loading?, to: :relation
        end
    end
end
