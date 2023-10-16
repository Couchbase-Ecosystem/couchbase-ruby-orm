# frozen_string_literal: true
# rubocop:todo all

module CouchbaseOrm
  module Timestamps
    # This module handles the behavior for setting up document created at
    # timestamp.
    module Created
      extend ActiveSupport::Concern

      included do
        attribute :created_at, type: Time
        get_callbacks(:create) || define_callbacks(:create)
        set_callback :create, :before, :set_created_at
      end

      # Update the created_at attribute on the Document to the current time. This is
      # only called on create.
      #
      # @example Set the created at time.
      #   person.set_created_at
      def set_created_at
        return if created_at

        time = Time.configured.now
        self.updated_at = time if is_a?(Updated) && !updated_at_changed?
        self.created_at = time
      end
    end
  end
end
