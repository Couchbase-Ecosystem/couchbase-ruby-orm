module CouchbaseOrm
  module JsonSchema
    module Validation

      def validate_json_schema
        @validate_json_schema = true
      end

      def json_validation_config
        @json_validation_config ||= {
          enabled: @validate_json_schema,
      }.freeze
      end
    end
  end
end
