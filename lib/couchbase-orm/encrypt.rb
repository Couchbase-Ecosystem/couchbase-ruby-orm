# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        TANKER_ENCRYPTED_PREFIX = 'tanker_encrypted_'

        def encode_encrypted_attributes(attributes)
            attributes.clone.each do |key, value|
                if key.to_s.starts_with?(TANKER_ENCRYPTED_PREFIX)
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
                if key.starts_with?('encrypted$')
                    attributes.delete(key)
                    attributes[key.gsub('encrypted$', '')] = value[:ciphertext]
                end
            end
        end
    end
end
