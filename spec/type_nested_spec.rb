require File.expand_path("../support", __FILE__)

require "active_model"

class SubTypeTest < CouchbaseOrm::NestedDocument
    attribute :name, :string
    attribute :tags, :array, type: :string
    attribute :milestones, :array, type: :date
    attribute :flags, :array, type: :boolean
    attribute :things
    attribute :child, :nested, type: SubTypeTest
end

class TypeNestedTest < CouchbaseOrm::Base
    attribute :main, :nested, type: SubTypeTest
    attribute :others, :array, type: SubTypeTest
    attribute :flags, :array, type: :boolean
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
            "flags" => [],
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
    
    it "should not have a save method" do
        expect(SubTypeTest.new).to_not respond_to(:save)
    end

    it "should not cast a list" do
        expect{CouchbaseOrm::Types::Nested.new(type: SubTypeTest).cast([1,2,3])}.to raise_error(ArgumentError)
    end
    
    it "should not serialize a list" do
        expect{CouchbaseOrm::Types::Nested.new(type: SubTypeTest).serialize([1,2,3])}.to raise_error(ArgumentError)
    end

    it "should save a object with nested changes"  do
        obj = TypeNestedTest.new
        obj.main = SubTypeTest.new(name: "foo")
        obj.others = [SubTypeTest.new(name: "foo"), SubTypeTest.new(name: "bar")]
        obj.flags = [false, true]
        obj.save!
        obj.main.name = "bar"
        obj.others[0].name = "bar"
        obj.others[1].name = "baz"
        obj.flags[0] = true

        obj.save!
        obj = TypeNestedTest.find(obj.id)
        expect(obj.main.name).to eq "bar"
        expect(obj.others[0].name).to eq "bar"
        expect(obj.others[1].name).to eq "baz"
        expect(obj.flags).to eq [true, true]
    end

    describe "Validations" do
        class SubWithValidation < CouchbaseOrm::NestedDocument
            attribute :id, :string
            attribute :name
            attribute :label
            attribute :child, :nested, type: SubWithValidation
            validates :name, presence: true
            validates :child, nested: true
        end

        class WithValidationParent < CouchbaseOrm::Base
            attribute :child, :nested, type: SubWithValidation
            attribute :children, :array, type: SubWithValidation
            validates :child, :children, nested: true
        end
        
        it "should generate an id" do
            expect(SubWithValidation.new.id).to be_present
        end

        it "should not regenerate the id after reloading parent" do
            obj = WithValidationParent.new
            obj.child = SubWithValidation.new(name: "foo")
            obj.save!
            expect(obj.child.id).to be_present
            old_id = obj.child.id
            obj.reload
            expect(obj.child.id).to eq(old_id)
        end

        it "should not override the param id" do
            expect(SubWithValidation.new(id: "foo").id).to eq "foo"
        end

        it "should validate the nested object" do
            obj = WithValidationParent.new
            obj.child = SubWithValidation.new
            expect(obj).to_not be_valid
            expect(obj.errors[:child]).to eq ["is invalid"]
            expect(obj.child.errors[:name]).to eq ["can't be blank"]

        end

        it "should validate the nested objects in an array" do
            obj = WithValidationParent.new
            obj.children = [SubWithValidation.new(name: "foo"), SubWithValidation.new]
            expect(obj).to_not be_valid
            expect(obj.errors[:children]).to eq ["is invalid"]
            expect(obj.children[1].errors[:name]).to eq ["can't be blank"]
        end

        it "should validate the nested in the nested object" do
            obj = WithValidationParent.new
            obj.child = SubWithValidation.new name: "foo", label: "parent"
            obj.child.child = SubWithValidation.new label: "child"

            expect(obj).to_not be_valid
            expect(obj.child).to_not be_valid
            expect(obj.child.child).to_not be_valid

            expect(obj.errors[:child]).to eq ["is invalid"]
            expect(obj.child.errors[:child]).to eq ["is invalid"]
            expect(obj.child.child.errors[:name]).to eq ["can't be blank"]
        end
    end
end
