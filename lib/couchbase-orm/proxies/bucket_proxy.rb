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

            self.class.define_method(:view) do |design, view, **opts, &block|
                @results = nil if @current_query != "#{design}_#{view}"
                @current_query = "#{design}_#{view}"
                return @results if @results

                CouchbaseOrm.logger.debug "View - #{design} #{view}"
                @results = ResultsProxy.new(@proxyfied.send(:view, design, view, **opts, &block))
            end
        end
    
        def method_missing(name, *args, **options, &block)
            @proxyfied.public_send(name, *args, **options, &block)
        end
    end
end
