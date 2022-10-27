module CouchbaseOrm
    module Relation
        extend ActiveSupport::Concern

        class CouchbaseOrm_Relation
            def initialize(model:, where: where = nil, order: order = nil, limit: limit = nil, _not: _not = false)
                CouchbaseOrm::logger.debug "CouchbaseOrm_Relation init: #{model} where:#{where.inspect} not:#{_not.inspect} order:#{order.inspect} limit: #{limit}"
                @model = model
                @limit = limit
                @where = []
                @order = {}
                @order = merge_order(**order) if order
                @where = merge_where(where, _not) if where
                CouchbaseOrm::logger.debug "- #{to_s}"
            end

            def to_s
                "CouchbaseOrm_Relation: #{@model} where:#{@where.inspect} order:#{@order.inspect} limit: #{@limit}"
            end

            def to_n1ql
                bucket_name = @model.bucket.name
                where = build_where
                order = build_order
                limit = build_limit
                "select raw meta().id from `#{bucket_name}` where #{where} order by #{order} #{limit}"
            end

            def query
                CouchbaseOrm::logger.debug("Query: #{self}")
                n1ql_query = to_n1ql
                result = @model.cluster.query(n1ql_query, Couchbase::Options::Query.new(scan_consistency: :request_plus))
                CouchbaseOrm.logger.debug { "Relation query: #{n1ql_query} return #{result.rows.to_a.length} rows" }
                N1qlProxy.new(result)
            end

            def ids
                query.to_a
            end

            def first
                result = @model.cluster.query(self.limit(1).to_n1ql, Couchbase::Options::Query.new(scan_consistency: :request_plus))
                first_id = result.rows.to_a.first
                @model.find(first_id) if first_id
            end

            def last
                result = @model.cluster.query(to_n1ql, Couchbase::Options::Query.new(scan_consistency: :request_plus))
                last_id = result.rows.to_a.last
                @model.find(last_id) if last_id
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
                query.results { |ids| @model.find(ids) }.to_ary
            end

            alias :to_a :to_ary

            delegate :each, :map, :collect, :find, :select, :reduce, :to => :to_ary

            def [](*args)
                to_ary[*args]
            end

            def delete_all
                CouchbaseOrm::logger.debug{ "Delete all: #{self}" }
                ids = query.to_a
                CouchbaseOrm::Connection.bucket.default_collection.remove_multi(ids) unless ids.empty?
            end

            def where(**conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: merge_where(conds)))
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

            private

            def build_limit
                @limit ? "limit #{@limit}" : ""
            end

            def initializer_arguments
                { model: @model, order: @order, where: @where, limit: @limit }
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

            def build_order
                order = @order.map do |key, value|
                    "#{key} #{value}"
                end.join(", ")
                order.empty? ? "meta().id" : order
            end
            
            def build_where
                ([[:type, @model.design_document]] + @where).map do |key, value, opt|
                    opt == :not ? 
                        @model.build_not_match(key, value) : 
                        @model.build_match(key, value)
                end.join(" AND ")
            end
        end

        module ClassMethods
            def where(**conds)
                CouchbaseOrm_Relation.new(model: self, where: conds)
            end

            def not(**conds)
                CouchbaseOrm_Relation.new(model: self, where: conds, _not: true)
            end

            def order(*ordersl, **ordersh)
                order = ordersh.reverse_merge(ordersl.map{ |o| [o, :asc] }.to_h)
                CouchbaseOrm_Relation.new(model: self, order: order)
            end

            def limit(limit)
                CouchbaseOrm_Relation.new(model: self, limit: limit)
            end

            def all
                CouchbaseOrm_Relation.new(model: self)
            end

            delegate :ids, :delete_all, :count, :empty?, :select, :reduce, to: :all
        end
    end
end
