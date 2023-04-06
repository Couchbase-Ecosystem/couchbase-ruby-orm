module CouchbaseOrm
    module IgnoredProperties
        def ignored_properties=(properties)
            @@ignored_properties = properties.map(&:to_s)
        end

        def ignored_properties(*args)
            if args.any?
                CouchbaseOrm.logger.warn('Passing aruments to `.ignored_properties` is deprecated. PLease use `.ignored_properties=` intead.')
                return send :ignored_properties=, args
            end
            @@ignored_properties ||= []
        end
    end
end
