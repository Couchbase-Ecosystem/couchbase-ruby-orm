require File.expand_path("../support", __FILE__)

require "active_model"

class SubTypeEncryptedTest < CouchbaseOrm::NestedDocument
    attribute :name, :string
    attribute :secret, :encrypted
end

class TypeEncryptedTest < CouchbaseOrm::Base
    attribute :main, :nested, type: SubTypeEncryptedTest
    attribute :others, :array, type: SubTypeEncryptedTest
    attribute :secret, :encrypted
end

class SpecificAlgoTest < CouchbaseOrm::Base
    attribute :secret, :encrypted, alg: "3DES"
end

describe CouchbaseOrm::Types::Encrypted do
    it "prefix attribute on serialization" do
        obj = TypeEncryptedTest.new(secret: "mysecret")
        expect_serialized_secret(obj)
    end

    it "prefix attribute on nested objects" do
        obj = TypeEncryptedTest.new(main: SubTypeEncryptedTest.new(secret: "mysecret"))
        expect_serialized_secret(obj.main)
    end

    it "prefix attribute on array objects" do
        obj = TypeEncryptedTest.new(others: [SubTypeEncryptedTest.new(secret: "mysecret")])
        expect_serialized_secret(obj.others.first)
    end

    def expect_serialized_secret(obj)
        expect(obj.send(:serialized_attributes)["encrypted$secret"]).to eq({alg:"CB_MOBILE_CUSTOM", ciphertext: "mysecret"})
        expect(obj.send(:serialized_attributes)).to_not have_key "secret"
    end

    it "prefix with custom algo" do
        obj = SpecificAlgoTest.new(secret: "mysecret")
        expect(obj.send(:serialized_attributes)["encrypted$secret"]).to eq({alg:"3DES", ciphertext: "mysecret"})
        expect(obj.send(:serialized_attributes)).to_not include "secret"
    end

    it "decode encrypted attribute at reload" do
        obj = TypeEncryptedTest.create!(
            secret: "mysecret",
        )
        obj.save!
        obj.reload
        expect(obj.secret).to eq 'mysecret'
    end

    it "decode nested encrypted attribute at reload" do
        obj = TypeEncryptedTest.create!(
            main: SubTypeEncryptedTest.new(secret: "mysecret"),
        )
        obj.save!
        obj.reload
        expect(obj.main.secret).to eq 'mysecret'
    end

    it "decode array encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            others: [SubTypeEncryptedTest.new(secret: "mysecret")]
        )
        obj.save!
        obj.reload
        expect(obj.others.first.secret).to eq 'mysecret'
    end

    it "decode encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            secret: "mysecret",
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)
        expect(obj.secret).to eq 'mysecret'
    end

    it "decode nested encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            main: SubTypeEncryptedTest.new(secret: "mysecret"),
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)
        expect(obj.main.secret).to eq 'mysecret'
    end

    it "decode array encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            others: [SubTypeEncryptedTest.new(secret: "mysecret")]
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)
        expect(obj.others.first.secret).to eq 'mysecret'
    end
end
