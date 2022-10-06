# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        TANKER_ENCRYPTED_PREFIX = 'tanker_encrypted_'

        def encode_encrypted_attributes
            attributes.map do |key, value|
                if self.class.attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Encrypted)
                    ["encrypted$#{key}", {
                        alg: 'CB_MOBILE_CUSTOM',
                        ciphertext: value
                    }]
                else
                    [key,value]
                end
            end.to_h
        end

        def decode_encrypted_attributes(attributes)
            attributes.map do |key, value|
                key = key.to_s
                if key.start_with?('encrypted$')
                    [key.gsub('encrypted$', ''), value.with_indifferent_access[:ciphertext]]
                else
                    [key, value]
                end
            end.to_h
        end
    end
end
