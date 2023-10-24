# frozen_string_literal: true
# rubocop:todo all

module CouchbaseOrm
  module Timestamps
    # This module handles the behavior for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        set_callback :update, :before, -> {
          return if !frozen? && (new_record? || changed?)

          time = Time.current
          self.updated_at = time if is_a?(Updated) && !updated_at_changed?
        }, if: -> { attributes.has_key? 'updated_at' }
      end
    end
  end
end