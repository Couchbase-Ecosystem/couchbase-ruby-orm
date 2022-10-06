# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        TANKER_ENCRYPTED_PREFIX = 'tanker_encrypted_'

        def encode_encrypted_attributes(attributes)
            attributes.clone.each do |key, value|
                if self.class.attribute_types[key].is_a?(CouchbaseOrm::Types::Encrypted)
                    attributes["encrypted$#{key}"] = {
                        alg: 'CB_MOBILE_CUSTOM',
                        ciphertext: value
                    }
                    attributes.delete(key)
                end
            end
        end

        def decode_encrypted_attributes(attributes)
            attributes.clone.each do |key, value|
                key = key.to_s
                if key.start_with?('encrypted$')
                    attributes.delete(key)
                    attributes[key.gsub('encrypted$', '')] = value[:ciphertext]
                end
            end
        end
    end
end
