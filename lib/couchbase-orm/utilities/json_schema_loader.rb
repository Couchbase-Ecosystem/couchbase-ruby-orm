# frozen_string_literal: true

require 'couchbase-orm/json_schema_validator'

module CouchbaseOrm
  module JsonSchemaLoader
    include CouchbaseOrm::JsonSchema

    class Error < RuntimeError; end

    def config=(config)
      CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(ENV['CB_ORM_JSON_SCHEMA_PATH'])
      @@config = config
    end

  end
end
