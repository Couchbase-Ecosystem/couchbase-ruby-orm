# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class JsonSchemaBaseTest < CouchbaseOrm::Base
  attribute :name, :string
  attribute :numb, :integer

  design_document('JsonSchemaBaseTest')
  validate_json_schema
end

class UnknownTest < CouchbaseOrm::Base
  attribute :test, :boolean
  validate_json_schema
end

class EntitySnakecase < CouchbaseOrm::Base
  attribute :value, :string
  validate_json_schema
end

describe CouchbaseOrm::JsonSchema::Loader do

  after(:each) do
    reset_schemas
  end

  context "with validation enabled on model" do

    it "With no existing dir " do
      load_schemas("../dontexist")
      expect { CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema!({ :type => "Unknown" }) }.to raise_error CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for Unknown in .*\/dontexist/
    end

    it "Without existing json " do
      load_schemas("../empty-json-schema")
      expect { CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema!({ :type => "Unknown" }) }.to raise_error CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for Unknown in .*\/empty-json-schema/
    end

    it "with schema " do
      load_schemas("../json-schema")
      expect(CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema!({ :type => "JsonSchemaBaseTest" })).to include('"name"')
      expect { CouchbaseOrm::JsonSchema::Loader.instance.get_json_schema!({ :type => "Unknown" }) }.to raise_error CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for Unknown in .*\/json-schema/
    end
  end

  describe CouchbaseOrm::JsonSchema::Validator do
    after(:each) do
      reset_schemas
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

    it 'prevent saving with entity not define in schema files and raise' do
      load_schemas("../json-schema")
      expect { UnknownTest.create!(test: true) }.to raise_error CouchbaseOrm::JsonSchema::Loader::Error, /Schema not found for unknown_test in .*\/json-schema/
    end

    it 'prevent updating with entity not define in schema files and raise' do
      load_schemas("../json-schema")
      base = JsonSchemaBaseTest.create!(name: 'Juju', numb: 3)
      reset_schemas
      base.name = 'Pierre'
      expect { base.save }.to raise_error CouchbaseOrm::JsonSchema::Loader::Error, "Schema not found for JsonSchemaBaseTest in db/cborm_schemas/JsonSchemaBaseTest.json"
      base.delete
    end
  end

  context "with validation disabled on model" do
    let!(:original_config) { EntitySnakecase.instance_variable_get(:@json_validation_config) }
    before do
      EntitySnakecase.instance_variable_set(:@json_validation_config, {enabled: false})
    end
    after do
      EntitySnakecase.instance_variable_set(:@json_validation_config, original_config)
    end
    it "does not validate schema (even if scehma exists and is not valid)" do
      load_schemas("../json-schema")
      base = EntitySnakecase.create!(value: "value_one")
      base.value = "value_2"
      expect { base.save }.not_to raise_error CouchbaseOrm::JsonSchema::JsonValidationError
      base.delete
    end

  end

  context "with logger mode on model" do
    before do
      EntitySnakecase.instance_variable_set(:@json_validation_config, {enabled: true, mode: :logger})
    end
    it "does not raise error but log it" do
      load_schemas("../json-schema")
      base = EntitySnakecase.create!(value: "value_one")
      base.value = "value_2"
      expect(CouchbaseOrm.logger).to receive(:error)
      base.save
      base.delete
    end
  end

  context "when schema_path is set on model" do
    let!(:original_config) { EntitySnakecase.instance_variable_get(:@json_validation_config) }
    before do
      EntitySnakecase.instance_variable_set(:@json_validation_config, {enabled: true, mode: :strict, schema_path: 'spec/json-schema/specific_path.json'})
    end
    after do
      EntitySnakecase.instance_variable_set(:@json_validation_config, original_config)
    end
    it "loads schema from the specified path" do
      expect { EntitySnakecase.create!(value: "value_one") }.to raise_error CouchbaseOrm::JsonSchema::JsonValidationError, /did not contain a required property of 'foo' in schema/
    end
  end
end


# TODO : extract following helpers methods elsewhere

def load_schemas(file_relative_path)
  CouchbaseOrm::JsonSchema::Loader.instance.send(:instance_variable_set, :@schemas_directory, File.expand_path(file_relative_path, __FILE__))
end

def reset_schemas
  CouchbaseOrm::JsonSchema::Loader.instance.send(:instance_variable_set, :@schemas_directory, CouchbaseOrm::JsonSchema::Loader::JSON_SCHEMAS_PATH)
  CouchbaseOrm::JsonSchema::Loader.instance.instance_variable_get(:@schemas).clear
end
