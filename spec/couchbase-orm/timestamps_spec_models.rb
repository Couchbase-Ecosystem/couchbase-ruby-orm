# frozen_string_literal: true
require 'couchbase-orm/base'

class DocWithoutTimestamps < CouchbaseOrm::Base
  attribute :title
end

class DocWithCreatedAt < CouchbaseOrm::Base
  attribute :title
  attribute :created_at, :datetime
end

class DocWithUpdatedAt < CouchbaseOrm::Base
  attribute :title
  attribute :updated_at, :datetime
end

class DocWithBothTimestampsAttributes < CouchbaseOrm::Base
  attribute :title
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end

class SimpleNestedDoc < CouchbaseOrm::NestedDocument
  attribute :sub_title
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end

class DocWithBothTimestampsAttributesAndNested < CouchbaseOrm::Base
  attribute :title
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
  attribute :sub, :nested, type: SimpleNestedDoc
  attribute :subs, :array, type: SimpleNestedDoc
end