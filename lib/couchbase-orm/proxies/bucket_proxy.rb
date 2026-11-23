# frozen_string_literal: true, encoding: ASCII-8BIT

require 'couchbase-orm/proxies/n1ql_proxy'

module CouchbaseOrm
    class BucketProxy
        def initialize(proxyfied)
            raise ArgumentError, "Must proxy a non nil object" if proxyfied.nil?

            @proxyfied = proxyfied

            self.class.define_method(:n1ql) do
                N1qlProxy.new(@proxyfied.n1ql)
            end
        end
    
        def method_missing(name, *args, **options, &block)
            @proxyfied.public_send(name, *args, **options, &block)
        end
    end
end
