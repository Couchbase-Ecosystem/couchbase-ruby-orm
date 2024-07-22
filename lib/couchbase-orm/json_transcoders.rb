module CouchbaseOrm
  class JsonTranscoders < Couchbase::JsonTranscoder
    attr_reader :transcoders

    def initialize(model, *transcoders)
      @transcoders = transcoders.map {|klass| klass.new(model)}
      @transcoders << base_transcoder_class.new(model)
    end

    def decode(blob, _flags)
      transcoders.reverse.reduce(blob) do |result, transcoder|
        transcoder.decode(result, _flags)
      end
    end

    def encode(document)
      transcoders.reduce(document) do |result, transcoder|
        transcoder.encode(result)
      end
    end

    private

    def base_transcoder_class
      CouchbaseOrm::JsonTranscoder
    end
  end
end