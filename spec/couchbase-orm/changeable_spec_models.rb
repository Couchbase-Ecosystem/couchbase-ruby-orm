# frozen_string_literal: true
# rubocop:todo all
require 'couchbase-orm/base'

class DocUnvalidOnUpdate < CouchbaseOrm::Base
  attribute :title
  validate :foo, on: :update

  def foo
    errors.add(:title, 'should not be updated')
  end
end
