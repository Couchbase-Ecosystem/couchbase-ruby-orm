# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)


class IndexTest < CouchbaseOrm::Base
    attribute :email, type: String
    attribute :name,  type: String, default: :joe
    ensure_unique :email, presence: false
end

class NoUniqueIndexTest < CouchbaseOrm::Base
    attribute :email, type: String
    attribute :name,  type: String, default: :joe

    index :email, presence: false
end

class IndexEnumTest < CouchbaseOrm::Base
    enum visibility: [:group, :authority, :public], default: :authority
    enum color: [:red, :green, :blue]
end


describe CouchbaseOrm::Index do
    after :each do
        IndexTest.all.map(&:destroy)
    end

    it "should prevent models being created if they should have unique keys" do
        joe = IndexTest.create!(email: 'joe@aca.com')
        expect { IndexTest.create!(email: 'joe@aca.com') }.to raise_error(CouchbaseOrm::Error::RecordInvalid)

        joe.email = 'other@aca.com'
        joe.save
        other = IndexTest.new(email: 'joe@aca.com')
        expect(other.save).to be(true)

        expect { IndexTest.create!(email: 'joe@aca.com') }.to raise_error(CouchbaseOrm::Error::RecordInvalid)
        expect { IndexTest.create!(email: 'other@aca.com') }.to raise_error(CouchbaseOrm::Error::RecordInvalid)

        joe.destroy
        other.destroy

        again = IndexTest.new(email: 'joe@aca.com')
        expect(again.save).to be(true)

        again.destroy
    end

    it "should provide helper methods for looking up the model" do
        joe = IndexTest.create!(email: 'joe@aca.com')

        joe_again = IndexTest.find_by_email('joe@aca.com')
        expect(joe).to eq(joe_again)

        joe.destroy
    end

    it "should clean up itself if dangling keys are left" do
        joe = IndexTest.create!(email: 'joe@aca.com')
        joe.delete # no callbacks are executed

        again = IndexTest.new(email: 'joe@aca.com')
        expect(again.save).to be(true)

        again.destroy
    end

    it "should work with nil values" do
        joe = IndexTest.create!
        expect(IndexTest.find_by_email(nil)).to eq(joe)

        joe.email = 'joe@aca.com'
        joe.save!
        expect(IndexTest.find_by_email('joe@aca.com')).to eq(joe)

        joe.email = nil
        joe.save!
        expect(IndexTest.find_by_email('joe@aca.com')).to eq(nil)
        expect(IndexTest.find_by_email(nil)).to eq(joe)

        joe.destroy
    end

    it "should work with enumerators" do
        # Test symbol
        enum = IndexEnumTest.create!(visibility: :public)
        expect(enum.visibility).to eq(3)
        enum.destroy

        # Test number
        enum = IndexEnumTest.create!(visibility: 2)
        expect(enum.visibility).to eq(2)
        enum.destroy

        # Test default
        enum = IndexEnumTest.create!
        expect(enum.visibility).to eq(2)
        enum.destroy

        # Test default default
        enum = IndexEnumTest.create!
        expect(enum.color).to eq(1)
    end

    it "should not overwrite index's that do not belong to the current model" do
        joe = NoUniqueIndexTest.create!
        expect(NoUniqueIndexTest.find_by_email(nil)).to eq(joe)

        joe.email = 'joe@aca.com'
        joe.save!
        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(joe)

        joe2 = NoUniqueIndexTest.create!
        joe2.email = 'joe@aca.com' # joe here is deliberate
        joe2.save!

        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(joe2)

        # Joe's indexing should not remove joe2 index
        joe.email = nil
        joe.save!
        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(joe2)

        # Test destroy
        joe.email = 'joe@aca.com'
        joe.save!
        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(joe)

        # Index should not be updated
        joe2.destroy
        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(joe)

        # index should be updated
        joe.email = nil
        joe.save!
        expect(NoUniqueIndexTest.find_by_email('joe@aca.com')).to eq(nil)

        joe.destroy
    end
end
