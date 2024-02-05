require 'couchbase-orm/utilities/properties_always_exists_in_document'

class DummyClass
  extend CouchbaseOrm::PropertiesAlwaysExistsInDocument
end

class DummyClass2
  extend CouchbaseOrm::PropertiesAlwaysExistsInDocument
end

RSpec.describe CouchbaseOrm::PropertiesAlwaysExistsInDocument do

  describe '#properties_always_exists_in_document=' do
    it 'Checks properties_always_exists_in_document value when initialize or not' do
      DummyClass.properties_always_exists_in_document = true
      expect(DummyClass.properties_always_exists_in_document).to be(true)
      expect(DummyClass2.properties_always_exists_in_document).to be(false)
    end

    it 'raises error when a non boolean value is passed' do
      expect { DummyClass.properties_always_exists_in_document = 'toto' }.to raise_error(ArgumentError)
    end
  end
end
