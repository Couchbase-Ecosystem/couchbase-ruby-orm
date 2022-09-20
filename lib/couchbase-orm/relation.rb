module CouchbaseOrm
    module Relation
        extend ActiveSupport::Concern

        class CouchbaseOrm_Relation
            def initialize(model:, where: where = nil, order: order = nil)
                @where = where || {}
                @order = order
                @model = model
            end
            
            def build_order
                order = @order
                if order.is_a?(Hash)
                    order = order.map do |key, value|
                        "#{key} #{value}"
                    end.join(", ")
                end
                order
            end

            def query
                @model.send(:run_query, @where.keys, @where.values, nil, custom_order: build_order, scan_consistency: :request_plus)
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

            def delete_all
                ids = query.to_a
                CouchbaseOrm::Connection.bucket.default_collection.remove_multi(ids) unless ids.empty?
            end

            def where(**conds)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(where: conds))
            end

            def order(**order)
                CouchbaseOrm_Relation.new(**initializer_arguments.merge(order: order))
            end

            def r_all
                CouchbaseOrm_Relation.new(**initializer_arguments)
            end

            def initializer_arguments
                { model: @model, order: @order, where: @where }
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

            def r_all
                CouchbaseOrm_Relation.new(model: self)
            end

            delegate :ids, :delete_all, :count, to: :r_all
        end
    end
end
