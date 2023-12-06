# frozen_string_literal: true

module CouchbaseOrm

  # Contains the behavior around inspecting documents via inspect.
  module Inspectable

    # Returns the class name plus its attributes.
    #
    # @example Inspect the document.
    #   person.inspect
    #
    # @return [ String ] A nice pretty string to look at.
    def inspect
      inspection = []
      inspection.concat(inspect_attributes)
      "#<#{self.class.name} id: #{respond_to?(:id)? id.inspect : 'no id'}, #{inspection * ', '}>"
    end

    private

    # Get an array of inspected fields for the document.
    #
    # @api private
    #
    # @example Inspect the defined fields.
    #   document.inspect_attributes
    #
    # @return [ String ] An array of pretty printed field values.
    def inspect_attributes
      attributes.map do |name, value|
          next if name.to_s == "id"
          "#{name}: #{value.inspect}"
      end.compact
    end
  end
end