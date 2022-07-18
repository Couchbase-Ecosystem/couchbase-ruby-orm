# frozen_string_literal: true

require 'active_model'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/try'

module CouchbaseOrm
    module N1ql
        extend ActiveSupport::Concern

        # sanitize for injection query
        def self.sanitize(value)
            if value.is_a?(String)
                value.gsub("'", "''").gsub("\\"){"\\\\"}.gsub('"', '\"')
            elsif value.is_a?(Array)
                value.map{ |v| sanitize(v) }
            else
                value
            end
        end

        module ClassMethods
            # Defines a query N1QL for the model
            #
            # @param [Symbol, String, Array] names names of the views
            # @param [Hash] options options passed to the {Couchbase::N1QL}
            #
            # @example Define some N1QL queries for a model
            #  class Post < CouchbaseOrm::Base
            #    n1ql :all
            #    n1ql :by_rating, emit_key: :rating
            #  end
            #
            #  Post.by_rating do |response|
            #    # ...
            #  end
            # TODO: add range keys [:startkey, :endkey]
            def n1ql(name, query_fn: nil, emit_key: [], custom_order: nil, **options)
                emit_key = Array.wrap(emit_key)
                emit_key.each do |key|
                    raise "unknown emit_key attribute for n1ql :#{name}, emit_key: :#{key}" if key && @attributes[key].nil?
                end
                options = N1QL_DEFAULTS.merge(options)
                method_opts = {}
                method_opts[:emit_key] = emit_key

                @indexes ||= {}
                @indexes[name] = method_opts

                singleton_class.__send__(:define_method, name) do |**opts, &result_modifier|
                    opts = options.merge(opts).reverse_merge(scan_consistency: :request_plus)
                    values = convert_values(opts.delete(:key))
                    current_query = run_query(method_opts[:emit_key], values, query_fn, custom_order: custom_order, **opts.except(:include_docs))

                    if result_modifier
                        opts[:include_docs] = true
                        current_query.results &result_modifier
                    elsif opts[:include_docs]
                        current_query.results { |res| find(res) }
                    else
                        current_query.results
                    end
                end
            end
            N1QL_DEFAULTS = { include_docs: true }

            # add a n1ql query and lookup method to the model for finding all records
            # using a value in the supplied attr.
            def index_n1ql(attr, validate: true, find_method: nil, n1ql_method: nil)
                n1ql_method ||= "by_#{attr}"
                find_method ||= "find_#{n1ql_method}"

                validates(attr, presence: true) if validate
                n1ql n1ql_method, emit_key: attr

                instance_eval "
                                def self.#{find_method}(#{attr})
                                    #{n1ql_method}(key: #{attr})
                                end
                            "
            end

            private

            def convert_values(values)
                Array.wrap(values).compact.map do |v|
                    if v.class == String
                        "'#{N1ql.sanitize(v)}'"
                    elsif v.class == Date || v.class == Time
                        "'#{v.iso8601(3)}'"
                    else
                        N1ql.sanitize(v).to_s
                    end
                end
            end

            def build_where(keys, values)
                where = keys.each_with_index
                            .reject { |key, i| values.try(:[], i).nil? }
                            .map { |key, i| "#{key} = #{values[i] }" }
                            .join(" AND ")
                "type=\"#{design_document}\" #{"AND " + where unless where.blank?}"
            end

            # order-by-clause ::= ORDER BY ordering-term [ ',' ordering-term ]*
            # ordering-term ::= expr [ ASC | DESC ] [ NULLS ( FIRST | LAST ) ]
            # see https://docs.couchbase.com/server/5.0/n1ql/n1ql-language-reference/orderby.html
            def build_order(keys, descending)
                "#{keys.dup.push("meta().id").map { |k| "#{k} #{descending ? "desc" : "asc" }" }.join(",")}"
            end

            def build_limit(limit)
                limit ? "limit #{limit}" : ""
            end

            def run_query(keys, values, query_fn, custom_order: nil, descending: false, limit: nil, **options)
                if query_fn
                    result = query_fn.call(bucket, values, cluster)
                    N1qlProxy.new(result)
                else
                    bucket_name = bucket.name
                    where = build_where(keys, values)
                    order = custom_order || build_order(keys, descending)
                    limit = build_limit(limit)
                    select = "raw meta().id"
                    raise "select must be a string" unless select.is_a?(String)
                    n1ql_query = "select #{select} from `#{bucket_name}` where #{where} order by #{order} #{limit}"
                    result = cluster.query(n1ql_query, Couchbase::Options::Query.new(**options))
                    CouchbaseOrm.logger.debug "N1QL query: #{n1ql_query} return #{result.rows.to_a.length} rows"
                    N1qlProxy.new(result)
                end
            end
        end
    end
end
