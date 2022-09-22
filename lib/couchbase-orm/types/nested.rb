module CouchbaseOrm
    module Types
        class Nested < ActiveModel::Type::Value
            attr_reader :model_class

            def initialize(type:)
                raise ArgumentError, "type is nil" if type.nil?
                raise ArgumentError, "type is not a class : #{type.inspect}" unless type.is_a?(Class)
                
                @model_class = type
                super()
            end

            def cast(value)
                return nil if value.nil?
                return value if value.is_a?(@model_class)
                return @model_class.new(value) if value.is_a?(Hash)

                raise ArgumentError, "Nested: #{value.inspect} is not supported for cast"
            end
        
            def serialize(value)
                return nil if value.nil?
                return value.send(:serialized_attributes).except("id") if value.is_a?(@model_class)

                raise ArgumentError, "Nested: #{value.inspect} is not supported for serialization"
            end
        end
    end
end
