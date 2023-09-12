# frozen_string_literal: true

require "json"
require 'couchbase/json_transcoder'
require 'json-schema'

module CouchbaseOrm
  module JsonSchemaValidation
    class Error < RuntimeError; end

    @@schemas = nil

    def config=(config)
      initialize_schemas(ENV['CB_ORM_JSON_SCHEMA_PATH'])

      @@config = config
    end

    def json_schema_validate
      return [] if @@schemas.nil?
      class_name = self.class.name.demodulize
      schema = @@schemas[class_name]
      if schema.nil?
        CouchbaseOrm.logger.warn { "No schema found for entity #{class_name}" }
        return []
      end
      transcoder = Couchbase::JsonTranscoder.new
      json = transcoder.encode(self).first
      JSON::Validator.fully_validate(schema, json)
    end

    def initialize_schemas(schemas_directory)
      if schemas_directory.present?
        if File.directory?(schemas_directory)
          @@schemas = {}
          Dir.glob(File.join(schemas_directory, '*.json'))
             .each do |file_path|
            json_schema_value = File.read file_path
            entity_name = File.basename(file_path, '.json')
            @@schemas[entity_name] = json_schema_value
          end
        else
          CouchbaseOrm.logger.warn { "Not exist CB_ORM_JSON_SCHEMA_PATH directory #{schemas_directory}" }
        end
      end
      CouchbaseOrm.logger.debug { "SCHEMAS : #{@@schemas}" }

    end
  end

end
