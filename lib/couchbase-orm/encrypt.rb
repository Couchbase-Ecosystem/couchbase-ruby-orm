# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        def encode_encrypted_attributes
            attributes.filter_map do |key, value|
                if self.class.attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Encrypted)
                    next unless value
                    json_value = if value.is_a?(String)
                        Base64.strict_encode64(value)
                    else
                        raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute"
                    end

                    ["encrypted$#{key}", {
                        alg: self.class.attribute_types[key.to_s].alg,
                        ciphertext: json_value
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
                    [key.gsub('encrypted$', ''), Base64.decode64(value.with_indifferent_access[:ciphertext]).force_encoding(Encoding::UTF_8)]
                else
                    [key, value]
                end
            end.to_h
        end


        def to_json(*args, **kwargs)
            for_json.to_json(*args, **kwargs)
        end

        def for_json
            attributes.map do |key, value|
                if self.class.attribute_types[key.to_s].is_a?(CouchbaseOrm::Types::Encrypted)
                    next unless value
                    json_value = if value.is_a?(String)
                        Base64.strict_encode64(value)
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
