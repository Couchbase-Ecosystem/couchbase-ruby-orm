require "json"
require 'couchbase/json_transcoder'
require 'couchbase-orm/json_schema_validator'

module CouchbaseOrm
  class JsonTranscoder < Couchbase::JsonTranscoder

    attr_reader :ignored_properties

    def initialize(ignored_properties: [], **options, &block)
      @ignored_properties = ignored_properties
      super(**options, &block)
    end

    def decode(blob, _flags)
      original = super
      original&.except(*ignored_properties)
    end

    def encode(document)
      original = super
      CouchbaseOrm::JsonSchema::Validator.new.validate_entity(document, original[0]) if document.present? && !original.empty?
      original
    end
  end
end
