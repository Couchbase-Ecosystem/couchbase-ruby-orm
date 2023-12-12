module CouchbaseOrm
  module JsonSchema
    module Validation

      def validate_json_schema(mode: :strict)
        @json_validation_config = {
          enabled: true,
          mode: mode
        }.freeze
      end

      def json_validation_config
        @json_validation_config ||= {}
      end
    end
  end
end
