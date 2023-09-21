# frozen_string_literal: true

module CouchbaseOrm
  module JsonSchema
    class JsonValidationError < StandardError
      attr_reader :class_name, :errors

      def initialize(class_name, errors)
        @class_name = class_name
        @errors = errors
        super("[COUCHBASEORM]: Invalid document #{class_name} with errors : #{errors}")
      end

    end
  end
end
