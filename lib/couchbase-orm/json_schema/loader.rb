# frozen_string_literal: true
require 'singleton'

module CouchbaseOrm
  module JsonSchema
    class Loader
      include Singleton

      JSON_SCHEMAS_PATH = ENV['CB_ORM_JSON_SCHEMA_PATH']

      attr_reader :schemas

      def initialize(json_schemas_path = JSON_SCHEMAS_PATH)
        @schemas_directory = json_schemas_path
        initialize_schemas
      end

      def extract_type(entity = {})
        entity[:type]
      end

      def get_json_schema(entity)
        document_type = extract_type(entity)
        schemas[document_type] if document_type && schemas
      end

      private

      attr_reader :schemas_directory

      def initialize_schemas
        @schemas = {}
        unless schemas_directory && File.directory?(schemas_directory)
          CouchbaseOrm.logger.warn { "Not exist CB_ORM_JSON_SCHEMA_PATH directory #{schemas_directory}" }
          return
        end
        schemas.default_proc = proc do |hash, key|
          assign_schema(hash, key)
        end
      end

      def assign_schema(hash, key)
        file_path = File.join(schemas_directory, "#{key}.json")
        hash[key] =
          if File.exist?(file_path)
            json_schema_value = File.read file_path
            CouchbaseOrm.logger.info { "Schema loaded: #{key}" }
            CouchbaseOrm.logger.debug { "Loaded from: #{file_path}" }
            json_schema_value
          else
            CouchbaseOrm.logger.warn { "Unable to find schema: #{file_path}" }
            nil # store nil in hash to avoid future file system lookups
          end
      end
    end
  end
end
