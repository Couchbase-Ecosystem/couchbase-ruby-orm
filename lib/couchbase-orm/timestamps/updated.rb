# frozen_string_literal: true
require 'pry'

module CouchbaseOrm
  module Timestamps
    # This module handles the behavior for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        set_callback :save, :before, -> {
          return if frozen?
          return unless changed? || new_record?

          time = Time.current
          self.updated_at = time if !updated_at_changed?
        }, if: -> { attributes.has_key? 'updated_at' }
      end
    end
  end
end