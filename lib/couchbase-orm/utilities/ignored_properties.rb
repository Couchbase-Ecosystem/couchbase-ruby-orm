module CouchbaseOrm
    module IgnoredProperties
        def ignored_properties(*args)
            @@couchbase_orm_ignored_properties ||= []
            return @@couchbase_orm_ignored_properties if args.empty?
            @@couchbase_orm_ignored_properties += args.map(&:to_s)
        end
    end
end
