# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
  class TankerJsonTranscoder < Couchbase::JsonTranscoder

    attr_reader :attribute_types

    def initialize(model_class)
      @attribute_types = model_class.attribute_types
      super()
    end

    def decode(blob, _flags)
      blob.map do |key, value|
        key = key.to_s
        if key.start_with?('encrypted$')
          key = key.gsub('encrypted$', '')
          value = value.with_indifferent_access[:ciphertext]
        end
        [key, value]
      end.to_h
    end

    def encode(document)
      document.attributes.map do |key, value|
        # self.class was returning the Record model before then when copied here, it returns the TankerJsonTranscoder model
        # How to get the Record model here?
        type = attribute_types[key.to_s]
        if type.is_a?(CouchbaseOrm::Types::Encrypted)
          next unless value
          raise "Can not serialize value #{value} of type '#{value.class}' for Tanker encrypted attribute" unless value.is_a?(String)
          ["encrypted$#{key}", {
            alg: type.alg,
            ciphertext: value
          }]
        else
          [key, value]
        end
      end.compact.to_h
    end

  end
end
