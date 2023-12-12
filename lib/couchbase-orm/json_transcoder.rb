require "json"
require 'couchbase/json_transcoder'
require 'couchbase-orm/json_schema'

module CouchbaseOrm
  class JsonTranscoder < Couchbase::JsonTranscoder

    attr_reader :ignored_properties, :json_validation_config

    def initialize(ignored_properties: [], json_validation_config: {}, **options, &block)
      @ignored_properties = ignored_properties
      @json_validation_config = json_validation_config
      super(**options, &block)
    end

    def decode(blob, _flags)
      original = super
      original&.except(*ignored_properties)
    end

    def encode(document)
      original = super
      CouchbaseOrm::JsonSchema::Validator.new.validate_entity(document, original[0]) if document.present? && !original.empty? && json_validation_config[:enabled]
      original
    end
  end
end
