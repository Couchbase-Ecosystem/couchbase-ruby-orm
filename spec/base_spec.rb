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
    attribute :deleted_at, :datetime, precision: 6
end

describe CouchbaseOrm::Base do
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

    if ActiveModel::VERSION::MAJOR >= 6
        it "should have timestamp attributes for create in model" do
            expect(TimestampTest.timestamp_attributes_for_create_in_model).to eq(["created_at"])
        end
    end

    it "should generate a timestamp on creation" do
        base = TimestampTest.create!
        expect(base.created_at).to be_a(Time)
    end

    describe BaseTest do
        it_behaves_like "ActiveModel"
    end

    describe CompareTest do
        it_behaves_like "ActiveModel"
    end
end
