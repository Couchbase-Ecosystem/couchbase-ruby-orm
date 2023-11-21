# frozen_string_literal: true
require 'couchbase-orm'
require 'couchbase-orm/timestamps_spec_models'
require 'timecop'

describe CouchbaseOrm::Timestamps do
  context 'simple document' do
    describe 'without any related attributes' do
      let(:doc) { DocWithoutTimestamps.new }
      it 'does not run timestamp callbacks on create' do
        expect(doc).not_to receive(:updated_at=)
        expect(doc).not_to receive(:created_at=)
        doc.save
      end
      it 'does not run timestamp callbacks on update' do
        doc.save
        expect(doc).not_to receive(:updated_at=)
        expect(doc).not_to receive(:created_at=)
        doc.title = 'New title'
        doc.save
      end
    end

    describe 'with only created_at attribute' do
      let(:doc) { DocWithCreatedAt.new }
      it 'runs created_at timestamp callback on create' do
        expect(doc).to receive(:created_at=)
        expect(doc).not_to receive(:updated_at=)
        doc.save
      end
      it 'does not run timestamp callback on update' do
        doc.save
        expect(doc).not_to receive(:created_at=)
        expect(doc).not_to receive(:updated_at=)
        doc.title = 'New title'
        doc.save
      end
    end

    describe 'with only updated_at attribute' do
      let(:doc) { DocWithUpdatedAt.new }
      it 'does run timestamp callback on create only for updated_at' do
        expect(doc).not_to receive(:created_at=)
        expect(doc).to receive(:updated_at=)
        doc.save
      end
      it 'runs updated_at timestamp callback on update' do
        doc.save
        expect(doc).to receive(:updated_at=)
        expect(doc).not_to receive(:created_at=)
        doc.title = 'New title'
        doc.save
      end
    end

    describe 'with both created_at and updated_at attributes' do
      let(:doc) { DocWithBothTimestampsAttributes.new }
      it 'runs created_at timestamp callback on create' do
        expect(doc).to receive(:created_at=)
        expect(doc).to receive(:updated_at=)
        doc.save
      end
      it 'runs updated_at timestamp callback on update' do
        doc.save
        expect(doc).to receive(:updated_at=)
        doc.title = 'New title'
        doc.save
      end
    end
  end

  context 'with nested documents' do
    let(:nested_doc) { SimpleNestedDoc.new }
    describe 'when parent document has both timestamp attributes' do
      let(:doc) { DocWithBothTimestampsAttributesAndNested.new }
      it 'runs created_at timestamp callback on create' do
        expect(doc).to receive(:created_at=)
        expect(doc).to receive(:updated_at=)
        doc.save
        doc.sub = nested_doc
        expect(nested_doc).to receive(:created_at=)
      end
    end
  end
end
