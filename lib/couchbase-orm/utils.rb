# frozen_string_literal: true

module CouchbaseOrm
  # Utility functions for CouchbaseOrm.
  #
  # @api private
  module Utils
    extend self

    # A unique placeholder value that will never accidentally collide with
    # valid values. This is useful as a default keyword argument value when
    # you want the argument to be optional, but you also want to be able to
    # recognize that the caller did not provide a value for it.
    PLACEHOLDER = Object.new.freeze

    # Asks if the given value is a placeholder or not.
    #
    # @param [ Object ] value the value to compare
    #
    # @return [ true | false ] if the value is a placeholder or not.
    def placeholder?(value)
      value == PLACEHOLDER
    end
  end
end