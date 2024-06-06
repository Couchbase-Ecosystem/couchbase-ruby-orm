module CouchbaseOrm
    module QueryHelper
        extend ActiveSupport::Concern

        module ClassMethods

            def build_match(key, value)
                use_is_null = self.properties_always_exists_in_document
                key = "meta().id" if key.to_s == "id"
                case
                when value.nil? && use_is_null
                    "#{key} IS NULL"
                when value.nil? && !use_is_null
                    "#{key} IS NOT VALUED"
                when value.is_a?(Hash) && attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Array)
                    "any #{key.to_s.singularize} in #{key} satisfies (#{build_match_hash("#{key.to_s.singularize}", value)}) end"
                when value.is_a?(Hash) && !attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Array)
                    build_match_hash(key, value)
                when value.is_a?(Array) && value.include?(nil)
                    "(#{build_match(key, nil)} OR #{build_match(key, value.compact)})"
                when value.is_a?(Array)
                    "#{key} IN #{quote(value)}"
                when value.is_a?(Range)
                    build_match_range(key, value)
                else
                    "#{key} = #{quote(value)}"
                end
            end

            def build_match_hash(key, value)
                matches = []
                value.each do |k, v|
                    case k
                    when :_gt
                        matches << "#{key} > #{quote(v)}"
                    when :_gte
                        matches << "#{key} >= #{quote(v)}"
                    when :_lt
                        matches << "#{key} < #{quote(v)}"
                    when :_lte
                        matches << "#{key} <= #{quote(v)}"
                    when :_ne
                        matches << "#{key} != #{quote(v)}"
                    
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
                        matches << build_match("#{key}.#{k}", v)
                    end
                end
                
                matches.join(" AND ")
            end

            def build_match_range(key, value)
                matches = []
                matches << "#{key} >= #{quote(value.begin)}"
                if value.exclude_end?
                    matches << "#{key} < #{quote(value.end)}"
                else
                    matches << "#{key} <= #{quote(value.end)}"
                end
                matches.join(" AND ")
            end


            def build_not_match(key, value)
                use_is_null = self.properties_always_exists_in_document
                key = "meta().id" if key.to_s == "id"
                case
                when value.nil? && use_is_null
                    "#{key} IS NOT NULL"
                when value.nil? && !use_is_null
                    "#{key} IS VALUED"
                when value.is_a?(Array) && value.include?(nil)
                    "(#{build_not_match(key, nil)} AND #{build_not_match(key, value.compact)})"
                when value.is_a?(Array)
                    "#{key} NOT IN #{quote(value)}"
                else
                    "#{key} != #{quote(value)}"
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
                    formatedDate = value&.iso8601(@precision)
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
