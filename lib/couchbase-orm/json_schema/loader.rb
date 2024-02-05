# frozen_string_literal: true
require 'singleton'

module CouchbaseOrm
  module JsonSchema
    class Loader
      include Singleton
      class Error < StandardError; end

      JSON_SCHEMAS_PATH = 'db/cborm_schemas'

      attr_reader :schemas

      def initialize(json_schemas_path = JSON_SCHEMAS_PATH)
        @schemas_directory = json_schemas_path
        @schemas = {}
        unless File.directory?(schemas_directory)
          CouchbaseOrm.logger.info { "Directory not found #{schemas_directory}" }
        end
      end

      def extract_type(entity = {})
        entity[:type]
      end

      def get_json_schema!(entity, schema_path: nil)
        document_type = extract_type!(entity)

        return schemas[document_type] if schemas.key?(document_type)

        schema_path ||= File.join(schemas_directory, "#{document_type}.json")

        raise(Error, "Schema not found for #{document_type} in #{schema_path}") unless File.exist?(schema_path)

        schemas[document_type] = File.read schema_path
      end

      private

      attr_reader :schemas_directory

      def extract_type!(entity = {})
        extract_type(entity) || raise(Error, "No type found in #{entity}")
      end
    end
  end
end
