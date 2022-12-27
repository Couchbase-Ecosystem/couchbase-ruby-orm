require "json"

module CouchbaseOrm
  class JsonTranscoder

    attr_reader :ignored_properties
    def initialize(ignored_properties: [])
        @ignored_properties = ignored_properties
    end
    # @param [Object] document
    # @return [Array<String, Integer>] pair of encoded document and flags
    def encode(document)
      [JSON.generate(document), (0x02 << 24) | 0x06]
    end

    # @param [String, nil] blob string of bytes, containing encoded representation of the document
    # @param [Integer, :json] _flags bit field, describing how the data encoded
    # @return Object decoded document
    def decode(blob, _flags)
      JSON.parse(blob).except(*ignored_properties) unless blob&.empty?
    end
  end
end
