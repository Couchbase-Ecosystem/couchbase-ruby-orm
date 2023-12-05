# frozen_string_literal: true
require 'couchbase-orm'
# require 'couchbase-orm/changeable'
require 'couchbase-orm/changeable_spec_models'

describe 'CouchbaseOrm::Changeable' do
  # This cover a fix of a bug currently on master
  it 'should unassign attributes on validation error' do
    doc = DocUnvalidOnUpdate.new(title: 'Test')
    doc.save
    expect(doc.title).to eq('Test')
    expect { doc.update!(title: 'changed wich assignation should not stay after raise') }.to raise_error(CouchbaseOrm::Error::RecordInvalid)
    expect(doc.title_was).to eq('Test') # raising in master with "changed wich assignation should not stay after raise"
    expect(doc.title).not_to eq(doc.title_was)
    expect(doc.title).to eq('changed wich assignation should not stay after raise')
  end

  it 'should have empty changes after loading a record from db' do
    doc = DocUnvalidOnUpdate.create(title: 'Test')
    expect(doc.changes).to be_empty
    doc = DocUnvalidOnUpdate.find(doc.id)
    expect(doc.changes).to be_empty
  end
end
