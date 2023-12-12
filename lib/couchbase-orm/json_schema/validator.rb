# frozen_string_literal: true

require "json"
require 'json-schema'

module CouchbaseOrm
  module JsonSchema
    class Validator

      def initialize(json_validation_config)
        @json_validation_config = json_validation_config
      end

      def validate_entity(entity, json)
        case @json_validation_config[:mode]
        when :strict
          strict_validation(entity, json)
        when :logger
          logger_validation(entity, json)
        else
          raise "Unknown validation mode #{@json_validation_config[:mode]}"
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
