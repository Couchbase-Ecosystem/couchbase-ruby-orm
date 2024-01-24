module CouchbaseOrm
    module PropertiesAlwaysExistsInDocument
        def properties_always_exists_in_document=(value)
            unless [true, false].include? value
                raise ArgumentError.new("properties_always_exists_in_document must be a boolean")
            end
            @properties_always_exists_in_document = value
        end

        def properties_always_exists_in_document
            @properties_always_exists_in_document ||= false
        end
    end
end
