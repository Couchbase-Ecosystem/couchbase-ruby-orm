
require 'couchbase'

module CouchbaseOrm
    class Connection
        @options = {}
        class << self
            attr_accessor :options
        end

        def self.cluster
            @cluster ||= begin
                options = Couchbase::Cluster::ClusterOptions.new
                options.authenticate(ENV["COUCHBASE_USER"], ENV["COUCHBASE_PASSWORD"])
                Couchbase::Cluster.connect('couchbase://127.0.0.1', options)
            end
        end

        def self.bucket
            @bucket ||= cluster.bucket(ENV["COUCHBASE_BUCKET"])
        end
    end
end
