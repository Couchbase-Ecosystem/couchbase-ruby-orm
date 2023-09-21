# frozen_string_literal: true

require "json"
require 'json-schema'

module CouchbaseOrm
  module JsonSchema
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
        error_results = common_validate(entity, json)
        raise JsonValidationError.new(Loader.instance.extract_type(entity), error_results) unless error_results.empty?
      end

      def logger_validation(entity, json)
        error_results = common_validate(entity, json)
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
