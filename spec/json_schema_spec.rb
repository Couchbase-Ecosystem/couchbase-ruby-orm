# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class BaseTest < CouchbaseOrm::Base
  attribute :name, :string
  attribute :numb, :integer

  def initialize(model = nil, ignore_doc_type: nil, **attributes)
    super
    self.class.design_document('BaseTest')
  end
end

class UnknownTest < CouchbaseOrm::Base
  attribute :name, :string
  attribute :numb, :integer
end

describe CouchbaseOrm::JsonSchema::Loader do

  before(:each) do
    CouchbaseOrm::JsonSchema::Loader.instance.reset
  end

  it "With no existing dir " do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../dontexist", __FILE__))
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "BaseTest" })).to be_nil
  end

  it "Without existing json " do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../empty-json-schema", __FILE__))
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "BaseTest" })).to be_nil
  end

  it "with schema " do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "BaseTest" })).to include('"name"')
    expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema({ :type => "Unknown" })).to be_nil

  end
end

describe CouchbaseOrm::JsonSchema::Validator do
  it "creation ok" do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    base = BaseTest.create!(name: "dsdsd", numb: 3)
    base.delete
  end

  it "creation with bad number" do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    expect { BaseTest.create!(name: "dsdsd", numb: 2) }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
  end

  it "update ok" do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    base = BaseTest.create!(name: "dsdsd", numb: 3)
    base.numb = 4
    base.save
    base.delete
  end

  it "update ok" do
    CouchbaseOrm::JsonSchema::Loader.instance.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    base = BaseTest.create!(name: "dsdsd", numb: 3)
    base.numb = 2
    expect { base.save }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
    base.delete
  end
end
