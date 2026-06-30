module CouchbaseOrm
    module QueryHelper
        extend ActiveSupport::Concern

        module ClassMethods

            def serialize_for_binding(value)
                if value.is_a?(Array)
                    value.map { |v| serialize_for_binding(v) }
                elsif [DateTime, Time].any? { |clazz| value.is_a?(clazz) } || (value.respond_to?(:acts_like?) && value.acts_like?(:time))
                    value.iso8601(@precision || 0)
                elsif value.is_a?(Date)
                    value.to_s
                else
                    value
                end
            end

            def bind(value, params)
                if value.nil?
                    nil
                else
                    params << serialize_for_binding(value)
                    "$#{params.length}"
                end
            end

            # Renders a value either as a positional parameter (when +params+ is
            # provided) or as an inline quoted literal (when it is nil).
            def resolve_value(value, params)
                params ? bind(value, params) : quote(value)
            end

            def build_match(key, value, params: nil)
                use_is_null = self.properties_always_exists_in_document
                key = "meta().id" if key.to_s == "id"
                case
                when value.nil? && use_is_null
                    "#{key} IS NULL"
                when value.nil? && !use_is_null
                    "#{key} IS NOT VALUED"
                when value.is_a?(Hash) && attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Array)
                    "any #{key.to_s.singularize} in #{key} satisfies (#{build_match_hash("#{key.to_s.singularize}", value, params: params)}) end"
                when value.is_a?(Hash) && !attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Array)
                    build_match_hash(key, value, params: params)
                when value.is_a?(Array) && value.include?(nil)
                    "(#{build_match(key, nil, params: params)} OR #{build_match(key, value.compact, params: params)})"
                when value.is_a?(Array)
                    "#{key} IN #{resolve_value(value, params)}"
                when value.is_a?(Range)
                    build_match_range(key, value, params: params)
                else
                    "#{key} = #{resolve_value(value, params)}"
                end
            end

            def build_match_hash(key, value, params: nil)
                matches = []
                value.each do |k, v|
                    case k
                    when :_gt
                        matches << "#{key} > #{resolve_value(v, params)}"
                    when :_gte
                        matches << "#{key} >= #{resolve_value(v, params)}"
                    when :_lt
                        matches << "#{key} < #{resolve_value(v, params)}"
                    when :_lte
                        matches << "#{key} <= #{resolve_value(v, params)}"
                    when :_ne
                        matches << "#{key} != #{resolve_value(v, params)}"

                    # TODO v2
                    # when :_in
                    #     matches << "#{key} IN #{quote(v)}"
                    # when :_nin
                    #     matches << "#{key} NOT IN #{quote(v)}"
                    # when :_like
                    #     matches << "#{key} LIKE #{quote(v)}"
                    # when :_nlike
                    #     matches << "#{key} NOT LIKE #{quote(v)}"
                    # when :_between
                    #     matches << "#{key} BETWEEN #{quote(v[0])} AND #{quote(v[1])}"
                    # when :_nbetween
                    #     matches << "#{key} NOT BETWEEN #{quote(v[0])} AND #{quote(v[1])}"
                    # when :_exists
                    #     matches << "#{key} IS #{v ? "" : "NOT "}VALUED"
                    # when :_regex
                    #     matches << "#{key} REGEXP #{quote(v)}"
                    # when :_nregex
                    #     matches << "#{key} NOT REGEXP #{quote(v)}"
                    # when :_match
                    #     matches << "#{key} MATCH #{quote(v)}"
                    # when :_nmatch
                    #     matches << "#{key} NOT MATCH #{quote(v)}"

                    # TODO v3
                    # when :_any
                    #     matches << "#{key} ANY #{quote(v)}"
                    # when :_nany
                    #     matches << "#{key} NOT ANY #{quote(v)}"
                    # when :_all
                    #     matches << "#{key} ALL #{quote(v)}"
                    # when :_nall
                    #     matches << "#{key} NOT ALL #{quote(v)}"
                    # when :_within
                    #     matches << "#{key} WITHIN #{quote(v)}"
                    #when :_nwithin
                    #    matches << "#{key} NOT WITHIN #{quote(v)}"
                    else
                        matches << build_match("#{key}.#{k}", v, params: params)
                    end
                end

                matches.join(" AND ")
            end

            def build_match_range(key, value, params: nil)
                matches = []
                matches << "#{key} >= #{resolve_value(value.begin, params)}"
                if value.exclude_end?
                    matches << "#{key} < #{resolve_value(value.end, params)}"
                else
                    matches << "#{key} <= #{resolve_value(value.end, params)}"
                end
                matches.join(" AND ")
            end


            def build_not_match(key, value, params: nil)
                use_is_null = self.properties_always_exists_in_document
                key = "meta().id" if key.to_s == "id"
                case
                when value.nil? && use_is_null
                    "#{key} IS NOT NULL"
                when value.nil? && !use_is_null
                    "#{key} IS VALUED"
                when value.is_a?(Array) && value.include?(nil)
                    "(#{build_not_match(key, nil, params: params)} AND #{build_not_match(key, value.compact, params: params)})"
                when value.is_a?(Array)
                    "#{key} NOT IN #{resolve_value(value, params)}"
                else
                    "#{key} != #{resolve_value(value, params)}"
                end
            end

            def serialize_value(key, value_before_type_cast)
                value =
                    if value_before_type_cast.is_a?(Array)
                        value_before_type_cast.map do |v|
                            attribute_types[key.to_s].serialize(attribute_types[key.to_s].cast(v))
                        end
                    else
                        attribute_types[key.to_s].serialize(attribute_types[key.to_s].cast(value_before_type_cast))
                    end
                CouchbaseOrm.logger.debug { "convert_values: #{key} => #{value_before_type_cast.inspect} => #{value.inspect} #{value.class} #{attribute_types[key.to_s]}" }
                value
            end

            def quote(value)
                if [String, Date].any? { |clazz| value.is_a?(clazz) }
                    "'#{N1ql.sanitize(value)}'"
                elsif [DateTime, Time].any? { |clazz| value.is_a?(clazz) }
                    formatedDate = value&.iso8601(@precision || 0)
                    "'#{N1ql.sanitize(formatedDate)}'"
                elsif value.is_a? Array
                    "[#{value.map{|v|quote(v)}.join(', ')}]"
                elsif value.nil?
                    nil
                else
                    N1ql.sanitize(value).to_s
                end
            end
        end
    end
end
