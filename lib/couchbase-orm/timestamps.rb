# frozen_string_literal: true

require "couchbase-orm/timestamps/created"
require "couchbase-orm/timestamps/updated"

module CouchbaseOrm

  # This module handles the behavior for setting up document created at and
  # updated at timestamps.
  module Timestamps
    extend ActiveSupport::Concern
    include Created
    include Updated
  end
end
