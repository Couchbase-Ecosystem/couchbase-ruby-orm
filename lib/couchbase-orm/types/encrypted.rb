module CouchbaseOrm
    module Types
        class Encrypted < ActiveModel::Type::Value  
            attr_reader :alg

            def initialize(alg: "CB_MOBILE_CUSTOM")
                @alg = alg
                super()
            end

            def serialize(value)
                return nil if value.nil?
                if value.try(:encoding) == Encoding::ASCII_8BIT
                    Base64.strict_encode64(value)
                elsif value.is_a?(String)
                    value
                else
                    raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute"
                end
            end
        end
    end
end
