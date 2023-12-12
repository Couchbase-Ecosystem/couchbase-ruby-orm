module CouchbaseOrm
  module IgnoredProperties
    def ignored_properties=(properties)
      @ignored_properties = properties.map(&:to_s)
    end

    def ignored_properties(*_args)
      @ignored_properties ||= []
    end
  end
end
