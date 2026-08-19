module CouchbaseOrm
    module Strict
        DEFAULT_VALUE = true

        def strict=(value)
            unless [true, false].include? value
                raise ArgumentError.new("strict must be a boolean")
            end
            @strict = value
        end

        def strict
            defined?(@strict) && !@strict.nil? ? @strict : DEFAULT_VALUE
        end
    end
end
