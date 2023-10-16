# frozen_string_literal: true
# rubocop:todo all

module CouchbaseOrm
  module Timestamps
    # This module handles the behavior for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        attribute :updated_at, type: Time
        get_callbacks(:update) || define_callbacks(:update)
        set_callback :update, :before, :set_updated_at
      end

      # Update the updated_at attribute on the Document to the current time. This is
      # only called on update.
      #
      # @example Set the updated at time.
      #   person.set_updated_at
      def set_updated_at
        return if able_to_set_updated_at?

        time = Time.configured.now
        self.updated_at = time if is_a?(Updated) && !updated_at_changed?
      end

      # Is the updated timestamp able to be set?
      #
      # @example Can the timestamp be set?
      #   document.able_to_set_updated_at?
      #
      # @return [ true | false ] If the timestamp can be set.
      def able_to_set_updated_at?
        !frozen? && (new_record? || changed?)
      end
    end
  end
end