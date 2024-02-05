require 'couchbase-orm/json_schema/validator'

RSpec.describe CouchbaseOrm::JsonSchema::Validator do
  describe '#validate_entity' do
    context 'when mode is set to an unknown value' do
      let(:json_validation_config) { { mode: :unknown } }
      let(:validator) { CouchbaseOrm::JsonSchema::Validator.new(json_validation_config) }
      it 'raises an error' do
        expect { validator.validate_entity({}, '') }.to raise_error('Unknown validation mode unknown')
      end
    end
  end
end
