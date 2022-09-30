class NestedValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
        if value.is_a?(Array)
            record.errors.add attribute, (options[:message] || "is invalid") unless value.map(&:valid?).all?
        else
            record.errors.add attribute, (options[:message] || "is invalid") unless
        value.nil? || value.valid?
        end

    end
end

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

                raise ArgumentError, "Nested: #{value.inspect} (#{value.class}) is not supported for cast"
            end
        
            def serialize(value)
                return nil if value.nil?
                value = @model_class.new(value) if value.is_a?(Hash)
                return value.send(:serialized_attributes) if value.is_a?(@model_class)

                raise ArgumentError, "Nested: #{value.inspect} (#{value.class}) is not supported for serialization"
            end
        end
    end
end
