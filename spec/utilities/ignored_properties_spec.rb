require 'couchbase-orm'
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

  describe '#ignored_properties' do
    # A fresh class per example, so the deprecated-setter test below can't
    # leak state into (or depend on run order with) any other example.
    let(:klass) { Class.new { extend CouchbaseOrm::IgnoredProperties } }

    it 'defaults to an empty array' do
      expect(klass.ignored_properties).to eq([])
    end

    it 'is deprecated as a setter and warns when called with arguments' do
      expect(CouchbaseOrm.logger).to receive(:warn).with(a_string_including('deprecated'))
      klass.ignored_properties(:legacy_property)
      expect(klass.ignored_properties).to eq(['legacy_property'])
    end
  end
end
