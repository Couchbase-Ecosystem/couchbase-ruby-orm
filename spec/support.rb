# frozen_string_literal: true, encoding: ASCII-8BIT
require 'simplecov'
require 'couchbase-orm'
require 'minitest/assertions'
require 'active_model/lint'
require 'pry'
require 'pry-stack_explorer'

SimpleCov.start do
    add_group 'Core', [/lib\/couchbase-orm\/(?!(proxies|utilities))/, 'lib/couchbase-orm.rb']
    add_group 'Proxies', 'lib/couchbase-orm/proxies'
    add_group 'Utilities', 'lib/couchbase-orm/utilities'
    add_group 'Specs', 'spec'
    minimum_coverage 94
end

if ENV["COUCHBASE_FLUSH"]
    CouchbaseOrm.logger.warn "Flushing Couchbase bucket '#{CouchbaseOrm::Connection.bucket.name}'"
    CouchbaseOrm::Connection.cluster.buckets.flush_bucket(CouchbaseOrm::Connection.bucket.name)
    raise "BucketFlushed"
end

shared_examples_for "ActiveModel" do
    include Minitest::Assertions
    include ActiveModel::Lint::Tests

    def assertions
        @__assertions__ ||= 0
    end

    def assertions=(val)
        @__assertions__ = val
    end

    ActiveModel::Lint::Tests.public_instance_methods.map { |method| method.to_s }.grep(/^test/).each do |method|
        example(method.gsub('_', ' ')) { send method }
    end

    before do
        @model = subject
    end
end
