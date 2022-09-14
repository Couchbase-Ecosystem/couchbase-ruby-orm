module CouchbaseOrm
    module Types
        class Date < ActiveModel::Type::Date
            def cast(value)
              super(value)
            end
        
            def serialize(value)
                value&.iso8601
            end
        end
    end
end
