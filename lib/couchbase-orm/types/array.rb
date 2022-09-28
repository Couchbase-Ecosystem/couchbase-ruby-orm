module CouchbaseOrm
    module Types
        class Array < ActiveModel::Type::Value
            attr_reader :type_class
            attr_reader :model_class

            def initialize(type: nil)
                if type.is_a?(Class) && type < CouchbaseOrm::NestedDocument
                    @model_class = type
                    @type_class = CouchbaseOrm::Types::Nested.new(type: @model_class)
                else
                    @type_class = ActiveModel::Type.registry.lookup(type)
                end
                super()
            end

            def cast(values)
              return [] if values.nil?
              raise ArgumentError, "#{values.inspect} must be an array" unless values.is_a?(::Array)
              
              values.map(&@type_class.method(:cast))
            end
        
            def serialize(values)
                return [] if values.nil?
                values.map(&@type_class.method(:serialize))
            end
        end
    end
end
