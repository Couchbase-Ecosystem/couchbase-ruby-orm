# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)


class RelationModel < CouchbaseOrm::Base
    attribute :name, :string
    attribute :last_name, :string
    attribute :active, :boolean
    attribute :age, :integer
end

describe CouchbaseOrm::Relation do
    before(:each) do
        RelationModel.delete_all
        CouchbaseOrm.logger.debug "Cleaned before tests"
    end

    after(:all) do
        CouchbaseOrm.logger.debug "Cleanup after all tests"
        RelationModel.delete_all
    end

    it "should return a relation" do
        expect(RelationModel.all).to be_a(CouchbaseOrm::Relation::CouchbaseOrm_Relation)
    end

    it "should query with conditions" do
        RelationModel.create! name: :bob, active: true, age: 10
        RelationModel.create! name: :alice, active: true, age: 20
        RelationModel.create! name: :john, active: false, age: 30
        expect(RelationModel.where(active: true).count).to eq(2)

        expect(RelationModel.where(active: true).to_a.map(&:name)).to match_array(%w[bob alice])
        expect(RelationModel.where(active: true).where(age: 10).to_a.map(&:name)).to match_array(%w[bob])
    end

    it "should query with merged conditions" do
        RelationModel.create! name: :bob, active: true, age: 10
        RelationModel.create! name: :bob, active: false, age: 10
        RelationModel.create! name: :alice, active: true, age: 20
        RelationModel.create! name: :john, active: false, age: 30

        expect(RelationModel.where(active: true).where(name: 'bob').count).to eq(1)
    end


    it "should count without loading models" do
        RelationModel.create! name: :bob, active: true, age: 10
        RelationModel.create! name: :alice, active: false, age: 20

        expect(RelationModel).not_to receive(:find)

        expect(RelationModel.where(active: true).count).to eq(1)
    end

    it "Should delete_all" do
        RelationModel.create!
        RelationModel.create!
        RelationModel.delete_all
        expect(RelationModel.ids).to match_array([])
    end

    it "Should delete_all with conditions" do
        RelationModel.create!
        jane = RelationModel.create! name: "Jane"
        RelationModel.where(name: nil).delete_all
        expect(RelationModel.ids).to match_array([jane.id])
    end

    it "Should query ids" do
        expect(RelationModel.ids).to match_array([])
        m1 = RelationModel.create!
        m2 = RelationModel.create!
        expect(RelationModel.ids).to match_array([m1.id, m2.id])
    end

    it "Should query ids with conditions" do
        m1 = RelationModel.create!(active: true, name: "Jane")
        _m2 = RelationModel.create!(active: false, name: "Bob" )
        _m3 = RelationModel.create!(active: false, name: "Jane")
        expect(RelationModel.where(active: true, name: "Jane").ids).to match_array([m1.id])
    end

    it "Should query ids with conditions and limit" do
        RelationModel.create!(active: true, name: "Jane", age: 2)
        RelationModel.create!(active: false, name: "Bob", age: 3)
        m = RelationModel.create!(active: true, name: "Jane", age: 1)
        RelationModel.create!(active: false, name: "Jane", age: 0)

        expect(RelationModel.where(active: true, name: "Jane").order(:age).limit(1).ids).to match_array([m.id])
        expect(RelationModel.limit(1).where(active: true, name: "Jane").order(:age).ids).to match_array([m.id])
    end

    it "Should query ids with order" do
        m1 = RelationModel.create!(age: 10, name: 'b')
        m2 = RelationModel.create!(age: 20, name: 'a')
        expect(RelationModel.order(age: :desc).ids).to match_array([m2.id, m1.id])
        expect(RelationModel.order(age: :asc).ids).to match_array([m1.id, m2.id])
        expect(RelationModel.order(name: :desc).ids).to match_array([m1.id, m2.id])
        expect(RelationModel.order(name: :asc).ids).to match_array([m2.id, m1.id])
        expect(RelationModel.order(:name).ids).to match_array([m2.id, m1.id])
        expect(RelationModel.order(:age).ids).to match_array([m1.id, m2.id])
    end

    it "Should query with list order" do
        m1 = RelationModel.create!(age: 20, name: 'b')
        m2 = RelationModel.create!(age: 5, name: 'a')
        m3 = RelationModel.create!(age: 20, name: 'a')
        expect(RelationModel.order(:age, :name).ids).to match_array([m2.id, m3.id, m1.id])
    end

    it "Should query with chained order" do
        m1 = RelationModel.create!(age: 10, name: 'b')
        m2 = RelationModel.create!(age: 20, name: 'a')
        m3 = RelationModel.create!(age: 20, name: 'c')
        expect(RelationModel.order(age: :desc).order(name: :asc).ids).to match_array([m2.id, m3.id, m1.id])
    end

    it "Should query with order chained with list" do
        m1 = RelationModel.create!(age: 20, name: 'b')
        m2 = RelationModel.create!(age: 5, name: 'a')
        m3 = RelationModel.create!(age: 20, name: 'a', last_name: 'c')
        m4 = RelationModel.create!(age: 20, name: 'a', last_name: 'a')
        expect(RelationModel.order(:age, :name).order(:last_name).ids).to match_array([m2.id, m4.id, m3.id, m1.id])
    end

    it "Should query all" do
        m1 = RelationModel.create!(active: true)
        m2 = RelationModel.create!(active: false)
        expect(RelationModel.all).to match_array([m1, m2])
    end

    it "should query all with condition and order"  do
        m1 = RelationModel.create!(active: true, age: 10)
        m2 = RelationModel.create!(active: true, age: 20)
        _m3 = RelationModel.create!(active: false, age: 30)
        expect(RelationModel.where(active: true).order(age: :desc).all).to match_array([m2, m1])
        expect(RelationModel.all.where(active: true).order(age: :asc)).to match_array([m1, m2])
    end

    it "should return a relation when using not" do
        expect(RelationModel.not(active: true)).to be_a(CouchbaseOrm::Relation::CouchbaseOrm_Relation)
        expect(RelationModel.all.not(active: true)).to be_a(CouchbaseOrm::Relation::CouchbaseOrm_Relation)
    end

    it "should have a to_ary method" do
        expect(RelationModel.not(active: true)).to respond_to(:to_ary)
        expect(RelationModel.all.not(active: true)).to respond_to(:to_ary)
    end

    it "should have a each method" do
        expect(RelationModel.not(active: true)).to respond_to(:each)
        expect(RelationModel.all.not(active: true)).to respond_to(:each)
    end

    it "should query true boolean" do
        m1 = RelationModel.create!(active: true)
        _m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.where(active: true)).to match_array([m1])
    end

    it "should not query true boolean" do
        _m1 = RelationModel.create!(active: true)
        m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.not(active: true)).to match_array([m2]) # keep ActiveRecord compatibility by not returning _m3 
    end

    it "should query false boolean" do
        _m1 = RelationModel.create!(active: true)
        m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.where(active: false)).to match_array([m2])
    end

    it "should not query false boolean" do
        m1 = RelationModel.create!(active: true)
        _m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.not(active: false)).to match_array([m1]) # keep ActiveRecord compatibility by not returning _m3 
    end

    it "should query nil boolean" do
        _m1 = RelationModel.create!(active: true)
        _m2 = RelationModel.create!(active: false)
        m3 = RelationModel.create!(active: nil)
        expect(RelationModel.where(active: nil)).to match_array([m3])
    end

    it "should not query nil boolean" do
        m1 = RelationModel.create!(active: true)
        m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.not(active: nil)).to match_array([m1, m2])
    end

    it "should query nil and false boolean" do
        _m1 = RelationModel.create!(active: true)
        m2 = RelationModel.create!(active: false)
        m3 = RelationModel.create!(active: nil)
        expect(RelationModel.where(active: [false, nil])).to match_array([m2, m3])
    end

    it "should not query nil and false boolean" do
        m1 = RelationModel.create!(active: true)
        _m2 = RelationModel.create!(active: false)
        _m3 = RelationModel.create!(active: nil)
        expect(RelationModel.not(active: [false, nil])).to match_array([m1])
    end
end

