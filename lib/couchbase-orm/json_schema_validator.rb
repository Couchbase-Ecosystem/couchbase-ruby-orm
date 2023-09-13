# frozen_string_literal: true

require "json"
require 'json-schema'
require 'singleton'

module CouchbaseOrm

  module JsonSchema

    class Loader
      include Singleton

      @schemas = nil

      def reset
        @schemas = nil
      end

      def extract_type(entity)
        return entity[:type] if entity.present?

        nil
      end

      def get_json_schema(entity)
        class_name = extract_type(entity)
        if @schemas.present? && class_name.present?
          schema = @schemas[class_name]
          return schema if schema.present?
          CouchbaseOrm.logger.warn { "No schema found for entity #{class_name}" }
        end
        nil
      end

      def initialize_schemas(schemas_directory)
        if schemas_directory.present? && @schemas.nil?
          if File.directory?(schemas_directory)
            @schemas = {}
            Dir.glob(File.join(schemas_directory, '*.json'))
               .each do |file_path|
              json_schema_value = File.read file_path
              entity_name = File.basename(file_path, '.json')
              @schemas[entity_name] = json_schema_value
            end
          else
            CouchbaseOrm.logger.warn { "Not exist CB_ORM_JSON_SCHEMA_PATH directory #{schemas_directory}" }
          end
        end
        CouchbaseOrm.logger.debug { "SCHEMAS : #{@schemas}" }
      end
    end

    class JsonValidationError < StandardError
      attr_reader :class_name
      attr_reader :errors

      def initialize(class_name, errors)
        @class_name = class_name
        @errors = errors
        super("[COUCHBASEORM]: Invalid document #{class_name} with errors : #{errors}")
      end

    end

    class Validator

      def validate_entity(entity, json)
        if ENV['CB_ORM_JSON_SCHEMA_VALIDATION_TYPE'] == 'NO_STRICT'
          logger_validation(entity, json)
        else
          strict_validation(entity, json)
        end
      end

      private

      def strict_validation(entity, json)
        error_results = self.common_validate(entity, json)
        raise JsonValidationError.new(Loader.instance.extract_type(entity), error_results) unless error_results.empty?
      end

      def logger_validation(entity, json)
        error_results = self.common_validate(entity, json)
        CouchbaseOrm.logger.error { "[COUCHBASEORM]: Invalid document #{Loader.instance.extract_type(entity)} with errors : #{error_results}" } unless error_results.empty?
      end

      def common_validate(entity, json)

        schema = Loader.instance.get_json_schema(entity)
        return [] if schema.nil?
        JSON::Validator.fully_validate(schema, json)
      end

    end
  end
end
