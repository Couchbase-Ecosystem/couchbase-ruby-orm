module CouchbaseOrm
  module JsonSchema
    module Validation

      def validate_json_schema(mode: :strict, schema_path: nil)
        @json_validation_config = {
          enabled: true,
          mode: mode,
          schema_path: schema_path,
        }.freeze
      end

      def json_validation_config
        @json_validation_config ||= {}
      end
    end
  end
end
