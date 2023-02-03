require "json"
require 'couchbase/json_transcoder'

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
  end
end
