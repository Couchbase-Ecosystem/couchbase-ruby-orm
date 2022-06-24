
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
                options.authenticate("cb_admin", "cb_admin_pwd")

                cluster = Couchbase::Cluster.connect('couchbase://127.0.0.1', options) 
            end
        end

        def self.bucket
            @bucket ||= cluster.bucket("billeo-db-bucket")
        end
    end
end
