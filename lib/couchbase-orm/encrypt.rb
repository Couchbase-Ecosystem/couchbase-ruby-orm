# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    module Encrypt
        def encode_encrypted_attributes
            attributes.map do |key, value|
                type = self.class.attribute_types[key.to_s]
                if type.is_a?(CouchbaseOrm::Types::Encrypted)
                    next unless value
                    raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute" unless value.is_a?(String)
                    ["encrypted$#{key}", {
                        alg: type.alg,
                        ciphertext: value
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
                end
                [key, value]
            end.to_h
        end


        def to_json(*args, **kwargs)
            as_json.to_json(*args, **kwargs)
        end

        def as_json(*args, **kwargs)
            super(*args, **kwargs).map do |key, value|
                type = self.class.attribute_types[key.to_s]
                if type.is_a?(CouchbaseOrm::Types::Encrypted) && value
                    raise "Can not serialize value #{value} of type '#{value.class}' for encrypted attribute" unless value.is_a?(String)
                end
                [key, value]
            end.to_h.with_indifferent_access
        end

    end
end
