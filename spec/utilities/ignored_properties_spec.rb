require 'couchbase-orm/utilities/ignored_properties'

class DummyClass
  extend CouchbaseOrm::IgnoredProperties
end

class DummyClass2
  extend CouchbaseOrm::IgnoredProperties
end

RSpec.describe CouchbaseOrm::IgnoredProperties do

  describe '#ignored_properties=' do
    it 'does not mixup ignored properties between classes' do
      DummyClass.ignored_properties = [:property1, :property2]
      expect(DummyClass.ignored_properties).to eq(['property1', 'property2'])
      expect(DummyClass2.ignored_properties).to be_empty
    end
  end
end
