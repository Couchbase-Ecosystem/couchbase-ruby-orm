module CouchbaseOrm
    module IgnoredProperties
        def ignored_properties(*args)
            @@ignored_properties ||= []
            return @@ignored_properties if args.empty?
            @@ignored_properties += args.map(&:to_s)
        end
    end
end
