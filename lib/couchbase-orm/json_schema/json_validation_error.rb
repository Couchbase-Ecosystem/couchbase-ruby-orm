# frozen_string_literal: true

module CouchbaseOrm
  module JsonSchema
    class JsonValidationError < StandardError

      def initialize(class_name, errors)
        super("[COUCHBASEORM]: Invalid document #{class_name} with errors : #{errors}")
      end

    end
  end
end
