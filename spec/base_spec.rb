# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class BaseTest < CouchbaseOrm::Base
    attribute :name, :string
    attribute :job, :string
end

class CompareTest < CouchbaseOrm::Base
    attribute :age, :integer
end

class TimestampTest < CouchbaseOrm::Base
    attribute :created_at, :datetime, precision: 6
    attribute :updated_at, :datetime, precision: 6
end

class BaseTestWithIgnoredProperties < CouchbaseOrm::Base
    self.ignored_properties += [:deprecated_property]
    attribute :name, :string
    attribute :job, :string
end

class BaseTestWithPropertiesAlwaysExistsInDocument < CouchbaseOrm::Base
    self.properties_always_exists_in_document = true
    attribute :name, :string
end

class BaseTestWithTimeframe < CouchbaseOrm::Base
    attribute :name, :string
    attribute :start_date, :datetime
    attribute :age, :integer
end

class DocInvalidOnUpdate < CouchbaseOrm::Base
    attribute :title
    validate :foo, on: :update

    def foo
      errors.add(:title, 'should not be updated')
    end
  end

describe CouchbaseOrm::Base do

    it 'should have clean model after find' do
        base = BaseTest.create!(name: 'joe')
        base = BaseTest.find base.id
        expect(base.changed?).to be false
    end

    it 'stores not stringified changes' do
        compare = CompareTest.create!
        compare.age = '42'
        compare.save!
        expect(compare.saved_change_to_age).to eq [nil, 42]
    end

    it 'should update changed_attributes after update' do
        base = BaseTest.create!(name: 'joe')
        base = BaseTest.find base.id
        base.name = 'toto'
        base.save!
        expect(base.saved_change_to_name?).to be true
        expect(base.saved_change_to_name).to eq ["joe", "toto"]
    end
    it "should be comparable to other objects" do
        base = BaseTest.create!(name: 'joe')
        base2 = BaseTest.create!(name: 'joe')
        base3 = BaseTest.create!(ActiveSupport::HashWithIndifferentAccess.new(name: 'joe'))

        expect(base).to eq(base)
        expect(base).to be(base)
        expect(base).not_to eq(base2)

        same_base = BaseTest.find(base.id)
        expect(base).to eq(same_base)
        expect(base).not_to be(same_base)
        expect(base2).not_to eq(same_base)

        base.delete
        base2.delete
        base3.delete
    end

    it "should be inspectable" do
        base = BaseTest.create!(name: 'joe')
        expect(base.inspect).to eq("#<BaseTest id: \"#{base.id}\", name: \"joe\", job: nil>")
    end

    it "should load database responses" do
        base = BaseTest.create!(name: 'joe')
        resp = BaseTest.bucket.default_collection.get(base.id)

        base_loaded = BaseTest.new(resp, id: base.id)

        expect(base_loaded.id).to eq(base.id)
        expect(base_loaded).to eq(base)
        expect(base_loaded).not_to be(base)

        base.destroy
    end

    it "should not load objects if there is a type mismatch" do
        base = BaseTest.create!(name: 'joe')

        expect { CompareTest.find_by_id(base.id) }.to raise_error(CouchbaseOrm::Error::TypeMismatchError)

        base.destroy
    end

    it "raises ActiveModel::UnknownAttributeError on loading objects with unexpected properties" do
        too_much_properties_doc = {
            type: BaseTest.design_document,
            name: 'Pierre',
            job: 'dev',
            age: '42'
        }
        BaseTest.bucket.default_collection.upsert 'doc_1', too_much_properties_doc

        expect { BaseTest.find_by_id('doc_1') }.to raise_error(ActiveModel::UnknownAttributeError)

        BaseTest.bucket.default_collection.remove 'doc_1'
    end

    it "raises ActiveModel::UnknownAttributeError on loading objects with unexpected properties even valued to null" do
        too_much_properties_valued_to_null_doc = {
            type: BaseTest.design_document,
            name: 'Pierre',
            job: 'dev',
            age: nil
        }
        BaseTest.bucket.default_collection.upsert 'doc_1', too_much_properties_valued_to_null_doc

        expect { BaseTest.find_by_id('doc_1') }.to raise_error(ActiveModel::UnknownAttributeError)

        BaseTest.bucket.default_collection.remove 'doc_1'
    end

    it "loads objects even if there is a missing property in doc" do
        missing_properties_doc = {
            type: BaseTest.design_document,
            name: 'Pierre'
        }
        BaseTest.bucket.default_collection.upsert 'doc_1', missing_properties_doc
        base = BaseTest.find('doc_1')

        expect(base.name).to eq('Pierre')
        expect(base.job).to be_nil
        base.destroy
    end

    it "should support serialisation" do
        base = BaseTest.create!(name: 'joe')

        base_id = base.id
        expect(base.to_json).to eq({ id: base_id, name: 'joe', job: nil }.to_json)
        expect(base.to_json(only: :name)).to eq({ name: 'joe' }.to_json)

        base.destroy
    end

    it "should support dirty attributes" do
        begin
            base = BaseTest.new
            expect(base.changes.empty?).to be(true)
            expect(base.previous_changes.empty?).to be(true)

            base.name = 'change'
            expect(base.changes.empty?).to be(false)

            # Attributes are set by key
            base = BaseTest.new
            base[:name] = 'bob'
            expect(base.changes.empty?).to be(false)

            # Attributes are set by initializer from hash
            base = BaseTest.new({ name: 'bob' })
            expect(base.changes.empty?).to be(false)
            expect(base.previous_changes.empty?).to be(true)

            # A saved model should have no changes
            base = BaseTest.create!(name: 'joe')
            expect(base.changes.empty?).to be(true)
            expect(base.previous_changes.empty?).to be(true)

            # Attributes are copied from the existing model
            base = BaseTest.new(base)
            expect(base.changes.empty?).to be(false)
            expect(base.previous_changes.empty?).to be(true)
        ensure
            base.destroy if base.persisted?
        end
    end

    it "should try to load a model with nothing but an ID" do
        begin
            base = BaseTest.create!(name: 'joe')
            obj = CouchbaseOrm.try_load(base.id)
            expect(obj).to eq(base)
        ensure
            base.destroy
        end
    end

    it "should be able to create model with a custom ID" do
        begin
            base = BaseTest.create!(id: 'custom_id', name: 'joe')
            expect(base.id).to eq('custom_id')

            base = BaseTest.find('custom_id')
            expect(base.id).to eq('custom_id')
        ensure
            base&.destroy
        end
    end


    it "should try to load a model with nothing but single-multiple ID" do
        begin
            bases = [BaseTest.create!(name: 'joe')]
            objs = CouchbaseOrm.try_load(bases.map(&:id))
            expect(objs).to match_array(bases)
        ensure
            bases.each(&:destroy)
        end
    end

    it "should try to load a model with nothing but multiple ID" do
        begin
            bases = [BaseTest.create!(name: 'joe'), CompareTest.create!(age: 12)]
            objs = CouchbaseOrm.try_load(bases.map(&:id))
            expect(objs).to match_array(bases)
        ensure
            bases.each(&:destroy)
        end
    end

    it "should set the attribute on creation" do
        base = BaseTest.create!(name: 'joe')
        expect(base.name).to eq('joe')
    ensure
        base.destroy
    end

    it "should support getting the attribute by key" do
        base = BaseTest.create!(name: 'joe')
        expect(base[:name]).to eq('joe')
    ensure
        base.destroy
    end

    it "cannot change the id of a loaded object" do
        base = BaseTest.create!(name: 'joe')
        expect(base.id).to_not be_nil
        expect{base.id = "foo"}.to raise_error(RuntimeError, 'ID cannot be changed')
    end

    it "should generate a timestamp on creation" do
        base = TimestampTest.create!
        expect(base.created_at).to be_a(Time)
    end

    it "should find multiple ids at same time" do
        base1 = BaseTest.create!(name: 'joe1')
        base2 = BaseTest.create!(name: 'joe2')
        base3 = BaseTest.create!(name: 'joe3')
        expect(BaseTest.find([base1.id, base2.id, base3.id])).to eq([base1, base2, base3])
    end

    it "should find multiple ids at same time with a not found id with exception" do
        base1 = BaseTest.create!(name: 'joe1')
        base2 = BaseTest.create!(name: 'joe2')
        base3 = BaseTest.create!(name: 'joe3')
        expect { BaseTest.find([base1.id, 't', base3.id]) }.to raise_error(Couchbase::Error::DocumentNotFound)
    end

    it "should find multiple ids at same time with a not found id without exception" do
        base1 = BaseTest.create!(name: 'joe1')
        base2 = BaseTest.create!(name: 'joe2')
        base3 = BaseTest.create!(name: 'joe3')
        expect(BaseTest.find([base1.id, 't', 't', base2.id, base3.id], quiet: true)).to eq([base1, base2, base3])
    end

    describe BaseTest do
        it_behaves_like "ActiveModel"
    end

    describe CompareTest do
        it_behaves_like "ActiveModel"
    end

    it 'does not expose callbacks for nested that wont never be called' do
        expect{
            class InvalidNested < CouchbaseOrm::NestedDocument
                before_save {p "this should raise on loading class"}
            end

        }.to raise_error NoMethodError
    end

    it 'should unassign attributes on validation error' do
        doc = DocInvalidOnUpdate.new(title: 'Test')
        doc.save
        expect(doc.title).to eq('Test')
        expect { doc.update!(title: 'changed wich assignation should not stay after raise') }.to raise_error(CouchbaseOrm::Error::RecordInvalid)
        expect(doc.title_was).to eq('Test') # raising in master with "changed wich assignation should not stay after raise"
        expect(doc.title).not_to eq(doc.title_was)
        expect(doc.title).to eq('changed wich assignation should not stay after raise')
    end

    describe '.ignored_properties' do
        it 'returns an array of ignored properties' do
            expect(BaseTestWithIgnoredProperties.ignored_properties).to eq(['deprecated_property'])
        end

        context 'given a document with ignored properties' do
            let(:doc_id) { 'doc_1' }
            let(:document_properties) do
                {
                    'type' => BaseTestWithIgnoredProperties.design_document,
                    'name' => 'Pierre',
                    'job' => 'dev',
                    'deprecated_property' => 'depracted that could be removed on next save'
                }
            end
            let(:loaded_model) { BaseTestWithIgnoredProperties.find(doc_id) }

            before { BaseTestWithIgnoredProperties.bucket.default_collection.upsert doc_id, document_properties }
            after { BaseTestWithIgnoredProperties.bucket.default_collection.remove doc_id }

            it 'ignores the ignored properties on load from db (and dont raise)' do
                expect(loaded_model.attributes.keys).not_to include('deprecated_property')
                expect(loaded_model.name).to eq('Pierre')
                expect(BaseTestWithIgnoredProperties.bucket.default_collection.get(doc_id).content).to include(document_properties)
            end

            it 'delete the ignored properties on save' do
                loaded_model.name = 'Updated Name'
                expect{ loaded_model.save }.to change { BaseTestWithIgnoredProperties.bucket.default_collection.get(doc_id).content.keys.sort }.
                    from(%w[deprecated_property job name type]).
                    to(%w[job name type])
            end

            it 'does not raise for reload' do
                expect{ loaded_model.reload }.not_to raise_error
            end
        end
    end

    describe '.properties_always_exists_in_document' do
        it 'Uses NOT VALUED when properties_always_exists_in_document = false' do
            where_clause = BaseTest.where(name: nil)
            expect(where_clause.to_n1ql).to include("AND name IS NOT VALUED")
        end

        it 'Uses VALUED when properties_always_exists_in_document = false' do
            where_clause = BaseTest.where.not(name: nil)
            expect(where_clause.to_n1ql).to include("AND name IS VALUED")
        end

        it 'Uses IS NULL when properties_always_exists_in_document = true' do
            where_clause = BaseTestWithPropertiesAlwaysExistsInDocument.where(name: nil)
            expect(where_clause.to_n1ql).to include("AND name IS NULL")
        end

        it 'Uses IS NOT NULL when properties_always_exists_in_document = true' do
            where_clause = BaseTestWithPropertiesAlwaysExistsInDocument.where.not(name: nil)
            expect(where_clause.to_n1ql).to include("AND name IS NOT NULL")
        end
    end

    describe 'With a range in the where clause' do
        before do
            BaseTestWithTimeframe.delete_all
            BaseTestWithTimeframe.create!(name: 'january', start_date: DateTime.new(2020, 1, 1, 10, 0, 0), age: 10)
            BaseTestWithTimeframe.create!(name: 'midjanuary', start_date: DateTime.new(2020, 1, 15,11, 0, 0), age: 15)
            BaseTestWithTimeframe.create!(name: 'february', start_date: DateTime.new(2020, 2, 1,15, 0, 0), age: 20)
        end

        it 'manages the datetime range correctly' do
            result = BaseTestWithTimeframe.where(start_date: DateTime.new(2020, 1, 1, 11, 0,0)..DateTime.new(2020, 1, 31)).pluck(:name)
            expect(result).to eq(%w[midjanuary])
        end

        it 'manages the date range correctly' do
            result = BaseTestWithTimeframe.where(start_date: Date.new(2020, 1, 1)..Date.new(2020, 1, 31)).pluck(:name)
            expect(result).to eq(%w[january midjanuary])
        end

        it 'manages the time range correctly' do
            result = BaseTestWithTimeframe.where(start_date: Time.new(2020, 1, 1, 14, 35, 0)..Time.new(2020, 1, 31, 16, 35, 0)).pluck(:name)
            expect(result).to eq(%w[midjanuary])
        end

        it 'manages the integer range correctly' do
            result = BaseTestWithTimeframe.where(age: 12..25).pluck(:name)
            expect(result).to eq(%w[midjanuary february])
        end

        it 'manages the exclude end correctly' do
            result = BaseTestWithTimeframe.where(age: 10...15).pluck(:name)
            expect(result).to eq(%w[january])
        end
    end
end
