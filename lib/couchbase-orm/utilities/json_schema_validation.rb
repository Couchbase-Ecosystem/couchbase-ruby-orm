require 'json'
require 'json-schema'

#
module CouchbaseOrm
  #  Load a JSON schema from a file and cache it for later use.
  module JsonSchemaValidation
    def json_schema(schema_path = nil)
        @@json_schema ||= nil
        return @@json_schema unless schema_path

        File.open(schema_path) do |f|
          @@json_schema = JSON::Validator.parse_schema(JSON.parse(f))
        end
    end
  end
end
