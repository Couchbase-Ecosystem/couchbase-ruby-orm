module CouchbaseOrm
    module Types
        class DateTime < ActiveModel::Type::DateTime
            def cast(value)
              super(value)&.utc
            end
        
            def serialize(value)
                value&.iso8601
            end
        end
    end
end
