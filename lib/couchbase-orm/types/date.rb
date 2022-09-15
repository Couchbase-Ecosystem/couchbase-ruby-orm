module CouchbaseOrm
    module Types
        class Date < ActiveModel::Type::Date
            def serialize(value)
                value&.iso8601
            end
        end
    end
end
