# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class NestedModel < CouchbaseOrm::NestedDocument
    attribute :name, :string
    attribute :size, :integer
    attribute :child, :nested, type: NestedModel
end

class RelationParentModel < CouchbaseOrm::Base
    attribute :name, :string
    attribute :sub, :nested, type: NestedModel
    attribute :subs, :array, type: NestedModel
end

describe CouchbaseOrm::Relation do
    before(:each) do
        RelationParentModel.delete_all
        CouchbaseOrm.logger.debug "Cleaned before tests"
    end

    after(:all) do
        CouchbaseOrm.logger.debug "Cleanup after all tests"
        RelationParentModel.delete_all
    end

    it "should query on nested array attribute" do
        RelationParentModel.create(name: "parent_without_subs")
        parent = RelationParentModel.create(name: "parent")
        parent.subs = [
            NestedModel.new(name: "sub2"),
            NestedModel.new(name: "sub3")
        ]
        parent.save!

        expect(RelationParentModel.where(subs: {name: 'sub2'}).first).to eq parent
        expect(RelationParentModel.where(subs: {name: ['sub3', 'subX']}).first).to eq parent
    end

    it "should query on nested array with multiple attributes" do
        RelationParentModel.create(name: "parent_without_subs")
        parent = RelationParentModel.create(name: "parent")
        parent.subs = [
          NestedModel.new(name: "sub2", size: 2),
          NestedModel.new(name: "sub3", size: 3)
        ]
        parent.save!

        expect(RelationParentModel.where(subs: {name: 'sub2', size: 2}).first).to eq parent
        expect(RelationParentModel.where(subs: {name: 'sub2', size: 3}).first).to eq nil
    end

    it "should query by gte function" do
        parent = RelationParentModel.create(name: "parent")
        parent.subs = [
            NestedModel.new(name: "sub2", size: 2),
            NestedModel.new(name: "sub3", size: 3),
            NestedModel.new(name: "sub4", size: 4)
        ]
        parent.save!
        expect(RelationParentModel.where(subs: {size: {_gte: 3, _lt: 4}}).first).to eq parent
    end

    it "should query by nested attribute" do
        RelationParentModel.create(name: "parent_without_sub")
        parent = RelationParentModel.create(name: "parent")
        parent.sub = NestedModel.new(name: "sub")
        parent.save!
        expect(RelationParentModel.where('sub.name': 'sub').first).to eq parent
        expect(RelationParentModel.where(sub: {name: 'sub'}).first).to eq parent
        expect(RelationParentModel.where(sub: {name: ['sub', 'subX']}).first).to eq parent
        expect(RelationParentModel.where(sub: {name: ['subX']}).first).to be_nil

    end

    it "should query by grand child attribute" do
        RelationParentModel.create(name: "parent_without_sub")
        parent = RelationParentModel.create(name: "parent")
        parent.sub = NestedModel.new(name: "sub", child: NestedModel.new(name: "child"))
        parent.save!

        expect(RelationParentModel.where(sub: {child: {name: 'child'}}).first).to eq parent
        expect(RelationParentModel.where(sub: {child: {name: ['child', 'childX']}}).first).to eq parent
        expect(RelationParentModel.where(sub: {child: {name: ['childX']}}).first).to be_nil
    end
end

