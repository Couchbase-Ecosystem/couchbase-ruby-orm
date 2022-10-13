# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        def encode_encrypted_attributes
            attributes.map do |key, value|
                type = self.class.attribute_types[key.to_s]
                if type.is_a?(CouchbaseOrm::Types::Encrypted)
                    next unless value
                    json_value = if value.is_a?(String)
                        type.encode_base64 ? Base64.strict_encode64(value) : value
                    else
                        raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute"
                    end

                    ["encrypted$#{key}", {
                        alg: type.alg,
                        ciphertext: json_value
                    }]
                else
                    [key,value]
                end
            end.compact.to_h
        end

        def decode_encrypted_attributes(attributes)
            attributes.map do |key, value|
                key = key.to_s
                if key.start_with?('encrypted$')
                    key = key.gsub('encrypted$', '')
                    value = value.with_indifferent_access[:ciphertext]
                    type = self.class.attribute_types[key]
                    [key, type.encode_base64 ? Base64.decode64(value).force_encoding(Encoding::UTF_8) : value]
                else
                    [key, value]
                end
            end.to_h
        end


        def to_json(*args, **kwargs)
            as_json.to_json(*args, **kwargs)
        end

        def as_json(*args, **kwargs)
            super(*args, **kwargs).map do |key, value|
                type = self.class.attribute_types[key.to_s]
                if type.is_a?(CouchbaseOrm::Types::Encrypted) && value
                    json_value = if value.is_a?(String)
                        type.encode_base64 ? Base64.strict_encode64(value) : value
                    else
                        raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute"
                    end
                    [key, json_value]
                else
                    [key, value]
                end
            end.to_h.with_indifferent_access
        end

    end
end
