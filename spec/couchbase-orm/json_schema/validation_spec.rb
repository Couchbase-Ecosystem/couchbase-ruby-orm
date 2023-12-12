require 'couchbase-orm/json_schema/validation'

class DummyClass
  extend CouchbaseOrm::JsonSchema::Validation
  validate_json_schema
end

class DummyClass2
  extend CouchbaseOrm::JsonSchema::Validation
end

RSpec.describe CouchbaseOrm::JsonSchema::Validation do
  describe '#validate_json_schema' do
    it 'sets @validate_json_schema to true' do
      expect(DummyClass.json_validation_config[:enabled]).to be_truthy
    end

    it 'does not mixup @validate_json_schema between classes' do
      expect(DummyClass.json_validation_config[:enabled]).to be_truthy
      expect(DummyClass2.json_validation_config[:enabled]).to be_falsey
    end
  end
end