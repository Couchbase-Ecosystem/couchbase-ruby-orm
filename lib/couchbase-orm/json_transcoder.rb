require "json"
require 'couchbase/json_transcoder'
require 'couchbase-orm/json_schema'

module CouchbaseOrm
  class JsonTranscoder < Couchbase::JsonTranscoder

    attr_reader :ignored_properties, :json_validation_config

    def initialize(model_class)
      @ignored_properties = model_class.ignored_properties
      @json_validation_config = model_class.json_validation_config
      super()
    end

    def decode(blob, _flags)
      original = super
      original&.except(*ignored_properties)
    end

    def encode(document)
      original = super
      CouchbaseOrm::JsonSchema::Validator.new(json_validation_config).validate_entity(document, original[0]) if document.present? && !original.empty? && json_validation_config[:enabled]
      original
    end
  end
end
