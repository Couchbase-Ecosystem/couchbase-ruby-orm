
require 'mt-libcouchbase'
require 'couchbase'

module CouchbaseOrm
    class Connection
        @options = {}
        class << self
            attr_accessor :options
        end

        def self.bucket
            if @bucket.nil?
                options = Couchbase::Cluster::ClusterOptions.new
                options.authenticate("cb_admin", "cb_admin_pwd")

                cluster = Couchbase::Cluster.connect('couchbase://127.0.0.1', options)
                @bucket = cluster.bucket("billeo-db-bucket")
            end
        end
    end
end