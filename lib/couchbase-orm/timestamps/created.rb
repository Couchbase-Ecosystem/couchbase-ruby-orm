# frozen_string_literal: true
# rubocop:todo all

module CouchbaseOrm
  module Timestamps
    # This module handles the behavior for setting up document created at
    # timestamp.
    module Created
      extend ActiveSupport::Concern

      included do
        set_callback :create, :before, -> {
          return if created_at

          time = Time.current
          self.created_at = time
        }, if: -> { attributes.has_key?('created_at')}
      end
    end
  end
end
