module CouchbaseOrm
    module Types
        class Encrypted < ActiveModel::Type::Value  
            attr_reader :alg, :encode_base64

            def initialize(alg: "CB_MOBILE_CUSTOM", encode_base64: true)
                @alg = alg
                @encode_base64 = encode_base64
                super()
            end

            def serialize(value)
                return nil if value.nil?
                value
            end
        end
    end
end
