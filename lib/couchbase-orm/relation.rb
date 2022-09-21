module CouchbaseOrm
    module Relation
        extend ActiveSupport::Concern

        class CouchbaseOrm_Relation
            def initialize(model:, where: where = nil, order: order = nil, limit: limit = nil)
                CouchbaseOrm::logger.debug "CouchbaseOrm_Relation init: #{model} where:#{where.inspect} order:#{order.inspect} limit: #{limit}"
                @model = model
                @limit = limit
                @where = []
                @order = {}
                @order = merge_order(**order) if order
                @where = merge_where(where) if where
                CouchbaseOrm::logger.debug "- #{to_s}"
            end

            def to_s
                "CouchbaseOrm_Relation: #{@model} where:#{@where.inspect} order:#{@order.inspect} limit: #{@limit}"
            end

            def build_order
                order = @order.map do |key, value|
                    "#{key} #{value}"
                end.join(", ")
                order.empty? ? "meta().id" : order
            end
            
            def build_where
                ([[:type, @model.design_document]] + @where).map do |key, value|
                    @model.build_match(key, value)
                end.join(" AND ")
            end

            def build_limit
                @limit ? "limit #{@limit}" : ""
            end

            def to_n1ql
                bucket_name = @model.bucket.name
                where = build_where
                order = build_order
                limit = build_limit
                "select raw meta().id from `#{bucket_name}` where #{where} order by #{order} #{limit}"
            end

            def  query
                CouchbaseOrm::logger.debug("Query: #{self}")
                n1ql_query = to_n1ql
                result = @model.cluster.query(n1ql_query, Couchbase::Options::Query.new(scan_consistency: :request_plus))
                CouchbaseOrm.logger.debug { "Relation query: #{n1ql_query} return #{result.rows.to_a.length} rows" }
                N1qlProxy.new(result)
            end

            def ids
                query.to_a
            end

            def count
                query.count
            end

            def to_ary
                query.results { |res| @model.find(res) }
            end

            alias :to_a :to_ary

            delegate :each, :map, :collect, :to => :to_ary

            def delete_all
                ids = query.to_a
                CouchbaseOrm::Connection.bucket.default_collection.remove_multi(ids) unless ids.empty?
            end
            
            def merge_where(conds)
                @where + conds.to_a
            end

            def where(**conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: merge_where(conds)))
            end

            def merge_order(*lorder, **horder)
                raise ArgumentError, "invalid order passed by list: #{lorder.inspect}, must be symbols" unless lorder.all? { |o| o.is_a? Symbol }
                raise ArgumentError, "Invalid order passed by hash: #{horder.inspect}, must be symbol -> :asc|:desc" unless horder.all? { |k, v| k.is_a?(Symbol) && [:asc, :desc].include?(v) }
                @order
                    .merge(Array.wrap(lorder).map{ |o| [o, :asc] }.to_h)
                    .merge(horder)
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

            def initializer_arguments
                { model: @model, order: @order, where: @where, limit: @limit }
            end
        end

        module ClassMethods
            def where(**args)
                CouchbaseOrm_Relation.new(model: self, where: args)
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

            delegate :ids, :delete_all, :count, to: :all
        end
    end
end
