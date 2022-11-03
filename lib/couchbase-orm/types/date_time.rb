module CouchbaseOrm
    module Types
        class DateTime < ActiveModel::Type::DateTime
            def cast(value)
              value = Time.at(value) if value.is_a?(Float) || value.is_a?(Integer)
              super(value)&.utc
            end

            def serialize(value)
                value&.iso8601(@precision)
            end
        end
    end
end
