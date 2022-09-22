require File.expand_path("../support", __FILE__)

require "active_model"

class SubTypeTest < CouchbaseOrm::Base
    attribute :name
    attribute :tags, :array, type: :string
    attribute :milestones, :array, type: :date
    attribute :flags, :array, type: :boolean
    attribute :things
    attribute :child, :nested, type: SubTypeTest
end

class TypeNestedTest < CouchbaseOrm::Base
    attribute :main, :nested, type: SubTypeTest
    attribute :others, :array, type: SubTypeTest
end

describe CouchbaseOrm::Types::Nested do
    it "should be able to store and retrieve a nested object" do
        obj = TypeNestedTest.new
        obj.main = SubTypeTest.new
        obj.main.name = "foo"
        obj.main.tags = ["foo", "bar"]
        obj.main.child = SubTypeTest.new(name: "bar")
        obj.save!

        obj = TypeNestedTest.find(obj.id)
        expect(obj.main.name).to eq "foo"
        expect(obj.main.tags).to eq ["foo", "bar"]
        expect(obj.main.child.name).to eq "bar"
    end

    it "should be able to store and retrieve an array of nested objects" do
        obj = TypeNestedTest.new
        obj.others = [SubTypeTest.new, SubTypeTest.new]
        obj.others[0].name = "foo"
        obj.others[0].tags = ["foo", "bar"]
        obj.others[1].name = "bar"
        obj.others[1].tags = ["bar", "baz"]
        obj.others[1].child = SubTypeTest.new(name: "baz")
        obj.save!

        obj = TypeNestedTest.find(obj.id)
        expect(obj.others[0].name).to eq "foo"
        expect(obj.others[0].tags).to eq ["foo", "bar"]
        expect(obj.others[1].name).to eq "bar"
        expect(obj.others[1].tags).to eq ["bar", "baz"]
        expect(obj.others[1].child.name).to eq "baz"
    end

    it "should serialize to JSON" do
        obj = TypeNestedTest.new
        obj.others = [SubTypeTest.new, SubTypeTest.new]
        obj.others[0].name = "foo"
        obj.others[0].tags = ["foo", "bar"]
        obj.others[1].name = "bar"
        obj.others[1].tags = ["bar", "baz"]
        obj.others[1].child = SubTypeTest.new(name: "baz")
        obj.save!

        obj = TypeNestedTest.find(obj.id)
        expect(obj.send(:serialized_attributes)).to eq ({
            "id" => obj.id,
            "main" => nil,
            "others" => [
                {
                    "name" => "foo",
                    "tags" => ["foo", "bar"],
                    "milestones" => [],
                    "flags" => [],
                    "things" => nil,
                    "child" => nil
                },
                {
                    "name" => "bar",
                    "tags" => ["bar", "baz"],
                    "milestones" => [],
                    "flags" => [],
                    "things" => nil,
                    "child" => {
                        "name" => "baz",
                        "tags" => [],
                        "milestones" => [],
                        "flags" => [],
                        "things" => nil,
                        "child" => nil
                    }
                }
            ]
        })
    end
    it "should not cast a list" do
        expect{CouchbaseOrm::Types::Nested.new(type: SubTypeTest).cast([1,2,3])}.to raise_error(ArgumentError)
    end
    it "should not serialize a list" do
        expect{CouchbaseOrm::Types::Nested.new(type: SubTypeTest).serialize([1,2,3])}.to raise_error(ArgumentError)
    end
end
