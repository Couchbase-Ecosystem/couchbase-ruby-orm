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
    # Generated with SecureRandom.bytes(256)
    let(:the_secret) { "\x17`\x1F\xEE\el\xE0\x9F<\x94\xFE\x8A.\x1A\x92\xB9\xC3@\x86\x9Cp\xBEl\x86\x0E\x8CJ\tB\x97*U)\x96\x06\xA3\xE9\x84\xA6xW%\xDCT\x8C^\xEA\t\xC7\xD8\xFC\xF1\xD3\xD3\xE2\xEA\x89\xCBuUs\xB3\xFF'W>\xDE\x9CP\xA9\xDE%\xA2\xDE\x11\xFD\b\x9C\xD4\x87J,\x91\x02f\x16R\xDE\x908\x05\x1C\xF9\xDF{\x0F\xB3e\xB2\xB2\x96\xD7\xCC\x16As\xD3I\x02w\xE0\x8FL\xC6S\xEFP\xAC\x15\e^\xC4!\x15\"KF1\x17\x06\xA0N\x00\x18\xBA\x87\xEA?H\xD4<\xB5\xBCV\xB50\fc\xC9F\"\xF0B\eg%\x8E\x88\xD0\x9Bc\xE4\x93\t\x98\xC8\x87\xCB4]\xD9K\xA3\xDF\x13Q\xC0T\xCA\x91;\b\x9Cp\xE0\x7FR h\xDA\xB7\xD5\x869\f\xCA\x80\x802\x19\x19\xDD\x9DO\xAE}\xCA\eX\xA3\xA8\xBE\xE1\xBCW0g\x19@5n\r\xD8\xF3\x05\x7F4\x9CI\x1F3\xC0\xBDQJyG\v\xED!s\xD5\xD0&\xC1\x1A\xBC\x17\xFD\x9Cd\xB5\xAF\xB6U\x8A" }
    let(:base64_secret) { Base64.strict_encode64(the_secret) }

    it "prefix attribute on serialization" do
        obj = TypeEncryptedTest.new(secret: the_secret)
        expect_serialized_secret(obj)
    end

    it "prefix attribute on nested objects" do
        obj = TypeEncryptedTest.new(main: SubTypeEncryptedTest.new(secret: the_secret))
        expect_serialized_secret(obj.main)
    end

    it "prefix attribute on array objects" do
        obj = TypeEncryptedTest.new(others: [SubTypeEncryptedTest.new(secret: the_secret)])
        expect_serialized_secret(obj.others.first)
    end

    def expect_serialized_secret(obj)
        expect(obj.send(:serialized_attributes)["encrypted$secret"]).to eq({alg:"CB_MOBILE_CUSTOM", ciphertext: base64_secret})
        expect(obj.send(:serialized_attributes)).to_not have_key "secret"
        expect(JSON.parse(obj.to_json)["secret"]).to eq base64_secret
    end

    it "prefix with custom algo" do
        obj = SpecificAlgoTest.new(secret: the_secret)
        expect(obj.send(:serialized_attributes)["encrypted$secret"]).to eq({alg:"3DES", ciphertext: base64_secret})
        expect(obj.send(:serialized_attributes)).to_not include "secret"
    end

    it "decode encrypted attribute at reload" do
        obj = TypeEncryptedTest.create!(
            secret: the_secret,
        )
        obj.save!
        obj.reload
        expect(obj.secret).to eq the_secret
    end

    it "decode nested encrypted attribute at reload" do
        obj = TypeEncryptedTest.create!(
            main: SubTypeEncryptedTest.new(secret: the_secret),
        )
        obj.save!
        obj.reload
        expect(obj.main.secret).to eq the_secret
    end

    it "decode array encrypted attribute at reload" do
        obj = TypeEncryptedTest.create!(
            others: [SubTypeEncryptedTest.new(secret: the_secret)]
        )
        obj.save!
        obj.reload
        expect(obj.others.first.secret).to eq the_secret
    end

    it "decode encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            secret: the_secret,
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)
        expect(obj.secret).to eq the_secret
    end

    it "decode nested encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            main: SubTypeEncryptedTest.new(secret: the_secret),
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)

        expect(obj.main.secret).to eq the_secret
    end

    it "decode array encrypted attribute at load" do
        obj = TypeEncryptedTest.create!(
            others: [SubTypeEncryptedTest.new(secret: the_secret)]
        )
        obj.save!
        obj = TypeEncryptedTest.find(obj.id)

        expect(obj.others.first.secret).to eq the_secret
    end
end
