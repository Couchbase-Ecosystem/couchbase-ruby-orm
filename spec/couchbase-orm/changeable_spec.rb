# frozen_string_literal: true

require 'couchbase-orm'

class Doc < CouchbaseOrm::Base
  attribute :title
end

describe 'CouchbaseOrm::Changeable' do
  it 'should have empty changes after loading a record from db' do
    doc = Doc.create(title: 'Test')
    expect(doc.changes).to be_empty
    doc = Doc.find(doc.id)
    expect(doc.changes).to be_empty
  end
end
