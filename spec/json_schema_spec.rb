# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class JsonSchemaBaseTest < CouchbaseOrm::Base
  attribute :name, :string
  attribute :numb, :integer

  def initialize(model = nil, ignore_doc_type: nil, **attributes)
    super
    self.class.design_document('JsonSchemaBaseTest')
  end
end

class UnknownTest < CouchbaseOrm::Base
  attribute :test, :boolean
end

class EntitySnakecase < CouchbaseOrm::Base
  attribute :value, :string
end

describe CouchbaseOrm::JsonSchema::Loader do

  after(:each) do
    CouchbaseOrm::JsonSchema::Loader.instance.reset
  end

  it "With no existing dir " do
    load_schemas("../dontexist")
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "JsonSchemaBaseTest" })).to be_nil
  end

  it "Without existing json " do
    load_schemas("../empty-json-schema")
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "JsonSchemaBaseTest" })).to be_nil
  end

  it "with schema " do
    load_schemas("../json-schema")
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "JsonSchemaBaseTest" })).to include('"name"')
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "Unknown" })).to be_nil

  end
end

describe CouchbaseOrm::JsonSchema::Validator do
  after(:each) do
    CouchbaseOrm::JsonSchema::Loader.instance.reset
  end

  it "creation ok" do
        load_schemas("../json-schema")
    base = EntitySnakecase.create!(value: "value_one")
    base.delete
  end

  it "creation ko" do
    load_schemas("../json-schema")
    expect { EntitySnakecase.create!(value: "value_1") }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
  end

  it "update ok" do
    load_schemas("../json-schema")
    base = EntitySnakecase.create!(value: "value_one")
    base.value = "value_two"
    base.save
    base.delete
  end

  it "update ko" do
    load_schemas("../json-schema")
    base = EntitySnakecase.create!(value: "value_one")
    base.value = "value_2"
    expect { base.save }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
    base.delete
  end

  it "creation ok with design_document" do
    load_schemas("../json-schema")
    base = JsonSchemaBaseTest.create!(name: "dsdsd", numb: 3)
    base.delete
  end

  it "creation ko with design_document" do
    load_schemas("../json-schema")
    expect { JsonSchemaBaseTest.create!(name: "dsdsd", numb: 2) }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
  end

  it "update ok with design_document" do
    load_schemas("../json-schema")
    base = JsonSchemaBaseTest.create!(name: "dsdsd", numb: 3)
    base.numb = 4
    base.save
    base.delete
  end

  it "update ok with design_document" do
    load_schemas("../json-schema")
    base = JsonSchemaBaseTest.create!(name: "dsdsd", numb: 3)
    base.numb = 2
    expect { base.save }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
    base.delete
  end

  it "save with entity not define in schema files" do
    load_schemas("../json-schema")
    base = UnknownTest.create!(test: true)
    base.delete
  end

  it "update with entity not define in schema files" do
    load_schemas("../json-schema")
    base = UnknownTest.create!(test: true)
    base.test = false
    base.save
    base.delete
  end
end

def load_schemas(file_relative_path)
  CouchbaseOrm::JsonSchema::Loader.instance.send(:initialize_schemas, File.expand_path(file_relative_path, __FILE__))
end
