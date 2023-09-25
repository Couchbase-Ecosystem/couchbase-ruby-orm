# frozen_string_literal: true
require 'singleton'

module CouchbaseOrm
  module JsonSchema
    class Loader
      include Singleton

      JSON_SCHEMAS_PATH = ENV['CB_ORM_JSON_SCHEMA_PATH']

      attr_reader :schemas

      def initialize
        initialize_schemas
      end

      def extract_type(entity = {})
        entity[:type]
      end

      def get_json_schema(entity)
        class_name = extract_type(entity)
        if schemas&.present? && class_name.present?
          schema = schemas[class_name]
          return schema if schema&.present?
          CouchbaseOrm.logger.warn { "No schema found for entity #{class_name}" }
        end
        nil
      end

      private

      def initialize_schemas(schemas_directory = JSON_SCHEMAS_PATH)
        return if schemas

        return unless schemas_directory

        CouchbaseOrm.logger.warn { "Not exist CB_ORM_JSON_SCHEMA_PATH directory #{schemas_directory}" } unless File.directory?(schemas_directory)

        @schemas = {}
        Dir.glob(File.join(schemas_directory, '*.json'))
            .each do |file_path|
          json_schema_value = File.read file_path
          entity_name = File.basename(file_path, '.json')
          @schemas[entity_name] = json_schema_value
        end
        CouchbaseOrm.logger.debug { "SCHEMAS : #{schemas}" }
      end
    end
  end
end
