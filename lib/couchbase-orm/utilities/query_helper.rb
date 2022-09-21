module CouchbaseOrm
    module QueryHelper
        extend ActiveSupport::Concern

        module ClassMethods

            def build_match(key, value)
                case
                when value.nil?
                    "#{key} IS NOT VALUED"
                when value.is_a?(Array)
                    "#{key} IN #{quote(value)}"
                else
                    "#{key} = #{quote(value)}"
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
                if value.is_a? String
                    "'#{N1ql.sanitize(value)}'"
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
