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
                value
            end
        end
    end
end
