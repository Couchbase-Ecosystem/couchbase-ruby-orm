module CouchbaseOrm
    module Types
        class Timestamp < ActiveModel::Type::DateTime
            def cast(value)
              return nil if value.nil?
              return Time.at(value) if value.is_a?(Integer) || value.is_a?(Float)
              return Time.at(value.to_i) if value.is_a?(String) && value =~ /^[0-9]+$/
              return value.utc if value.is_a?(Time)
              super(value).utc
            end
        
            def serialize(value)
                value&.to_i
            end
        end
    end
end

