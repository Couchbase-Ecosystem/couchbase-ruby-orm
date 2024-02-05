require File.expand_path('../../support', __FILE__)
require 'couchbase-orm/json_schema/loader'

RSpec.describe CouchbaseOrm::JsonSchema::Loader do
  let(:loader) { described_class.send(:new, "#{Dir.pwd}/spec/json-schema") }

  describe '#extract_type' do
    it 'returns the type from the entity' do
      entity = { type: 'entity_snakecase' }
      expect(loader.extract_type(entity)).to eq('entity_snakecase')

      expect(loader.get_json_schema!(entity)).not_to be_nil
    end
  end

  describe '#get_json_schema' do
    context 'when schemas are present and document type exists' do
      let(:schemas) { { 'user' => { 'properties' => { 'name' => { 'type' => 'string' } } } } }

      before do
        allow(loader).to receive(:schemas).and_return(schemas)
      end

      it 'returns the schema for the given document type' do
        entity = { type: 'user' }
        expect(loader.get_json_schema!(entity)).to eq(schemas['user'])
      end

      it 'raise error if no schema found for the document type' do
        entity = { type: 'post' }
        expect { loader.get_json_schema!(entity) }.to raise_error(CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for post in .*\/json-schema/)
      end
    end

    context 'when schemas are not present or document type is missing' do
      it 'returns nil' do
        entity = { type: 'user' }
        expect { loader.get_json_schema!(entity) }.to raise_error(CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for user in .*\/json-schema/)
      end
    end
  end
end
