module CouchbaseOrm
    module Types
        class Timestamp < ActiveModel::Type::DateTime
            def cast(value)
                return nil if value.nil?

                value = if value.is_a?(Integer) || value.is_a?(Float)
                    Time.at(value)
                elsif value.is_a?(String) && value =~ /^[0-9]+$/
                    Time.at(value.to_i)
                elsif value.is_a?(Time)
                    value.utc
                else
                    value
                end
                super(value)
            end

            def serialize(value)
                value&.to_i
            end
        end
    end
end

