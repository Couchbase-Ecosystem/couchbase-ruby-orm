require 'json'
require 'json-schema'

#
module CouchbaseOrm
  #  Load a JSON schema from a file and cache it for later use.
  module JsonSchemaValidation
    class Error < RuntimeError; end

    @@config = nil
    def self.config
      @@config ||= {
        json_schema_path:  ENV['CB_ORM_JSON_SCHEMA_PATH']
      }
    end

    def self.config=(config)
      @@couchbase_orm_json_schema = nil
      @@config = config
    end

    def self.json_schema
      return @@couchbase_orm_json_schema if @@couchbase_orm_json_schema
      return nil unless config[:json_schema_path]

      File.open(config[:json_schema_path]) do |f|
        @@couchbase_orm_json_schema = f.read
      end

      raise Error, 'Provided schema is not a valid one' unless schema_valid?

      @@couchbase_orm_json_schema
    end

    def self.schema_valid?
      metaschema = JSON::Validator.validator_for_name('draft4').metaschema
      JSON::Validator.validate(metaschema, @@couchbase_orm_json_schema)
    end
  end
end
