# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class BaseTest < CouchbaseOrm::Base
  attribute :name, :string
  attribute :numb, :integer
end

describe CouchbaseOrm::JsonSchemaValidation do
  it "With no existing dir " do
    BaseTest.initialize_schemas(File.expand_path("../dontexist", __FILE__))

    base = BaseTest.create!(name: 'joe')
    expect(base.json_schema_validate).to be_empty
    expect(base).to eq(base)
    base.delete
  end

  it "Without existing xml " do
    BaseTest.initialize_schemas(File.expand_path("../empty-json-schema", __FILE__))
    base = BaseTest.create!(name: 'joe')
    expect(base.json_schema_validate).to be_empty
    expect(base).to eq(base)
    base.delete
  end

  it "with schema " do
    BaseTest.initialize_schemas(File.expand_path("../json-schema", __FILE__))
    base = BaseTest.create!(name: 'joe', numb: 4)
    expect(base.json_schema_validate).to be_empty
    expect(base).to eq(base)
    base.delete
  end
end
