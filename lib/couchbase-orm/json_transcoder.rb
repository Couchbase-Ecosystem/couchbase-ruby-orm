require "json"
require 'couchbase/json_transcoder'
require 'json-schema'

module CouchbaseOrm
  class JsonTranscoder < Couchbase::JsonTranscoder

    attr_reader :ignored_properties, :schema

    def initialize(ignored_properties: [], json_schema: nil, **options, &block)
      @ignored_properties = ignored_properties
      @schema = schema
      super(**options, &block)
    end

    # @param [Object] document
    # @return [Array<String, Integer>] pair of encoded document and flags
    def encode(document)
      super(document).tap do |json_blob, _flags|
        JSON::Validator.validate(schema, json_blob) if schema
      end
    end

    # @param [String, nil] blob string of bytes, containing encoded representation of the document
    # @param [Integer, :json] _flags bit field, describing how the data encoded
    # @return Object decoded document
    def decode(blob, _flags)
      original = super
      original&.except(*ignored_properties)
    end
  end
end
