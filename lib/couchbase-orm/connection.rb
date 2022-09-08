require 'couchbase'

module CouchbaseOrm
    class Connection

        def self.config
            @@config || raise(CouchbaseOrm::Error, 'Missing CouchbaseOrm connection config')
        end

        def self.config=(config)
            @@config = config
        end

        def self.cluster
            @cluster ||= begin
                 cb_config = Couchbase::Configuration.new
                 cb_config.connection_string = config[:connection_string] || raise(CouchbaseOrm::Error, 'Missing CouchbaseOrm connection string')
                 cb_config.username = config[:username] || raise(CouchbaseOrm::Error, 'Missing CouchbaseOrm username')
                 cb_config.password = config[:password] || raise(CouchbaseOrm::Error, 'Missing CouchbaseOrm password')
                 Couchbase::Cluster.connect(cb_config)
              end
        end

        def self.bucket
            @bucket ||= begin
                bucket_name = config[:bucket] || raise(CouchbaseOrm::Error, 'Missing CouchbaseOrm bucket name')
                cluster.bucket(bucket_name)
            end
        end
    end
end