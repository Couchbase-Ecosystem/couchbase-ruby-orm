# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)
require 'set'

class ViewTest < CouchbaseOrm::Base
    attribute :name, type: String
    enum rating: [:awesome, :good, :okay, :bad], default: :okay

    view :all
    view :by_rating, emit_key: :rating

    # This generates both:
    # view :by_rating, emit_key: :rating    # same as above
    # def self.find_by_rating(rating); end  # also provide this helper function
    index_view :rating
end


describe CouchbaseOrm::Views do
    before(:each) do
        ViewTest.all.each(&:destroy)
    rescue Couchbase::Error::DesignDocumentNotFound
        # ignore (FIXME: check before merge) mainly because if there is nothing in all we should not have an error
    end

    after(:each) do
        ViewTest.all.each(&:destroy)
    rescue Couchbase::Error::InternalServerFailure
        # ignore (FIXME: check before merge)
    rescue Couchbase::Error::DesignDocumentNotFound
        # ignore (FIXME: check before merge) (7.1)
    end

    it "should save a new design document" do
        begin
            ViewTest.bucket.view_indexes.drop_design_document(ViewTest.design_document, :production)
        rescue Couchbase::Error::InternalServerFailure
            # ignore if design document does not exist
        rescue Couchbase::Error::DesignDocumentNotFound
            # ignore if design document does not exist (7.1)
        end
        expect(ViewTest.ensure_design_document!).to be(true)
    end

    it "should not re-save a design doc if nothing has changed" do
        expect(ViewTest.ensure_design_document!).to be(false)
    end
    
    it "should return an empty array when there is no objects" do
        expect(ViewTest.all).to eq([])
    end

    it "should perform a map-reduce and return the view" do
        ViewTest.ensure_design_document!
        mod = ViewTest.create! name: :bob, rating: :good

        docs = ViewTest.all.collect { |ob|
            ob.destroy
            ob.name
        }
        expect(docs).to eq(['bob'])
    end

    it "should work with other keys" do
        ViewTest.ensure_design_document!
        ViewTest.create! name: :bob,  rating: :good
        ViewTest.create! name: :jane, rating: :awesome
        ViewTest.create! name: :greg, rating: :bad

        docs = ViewTest.by_rating(order: :descending).collect { |ob|
            ob.destroy
            ob.name
        }
        expect(docs).to eq(['greg', 'bob', 'jane'])
    end

    it "should return matching results" do
        ViewTest.ensure_design_document!
        ViewTest.create! name: :bob,  rating: :awesome
        ViewTest.create! name: :jane, rating: :awesome
        ViewTest.create! name: :greg, rating: :bad
        ViewTest.create! name: :mel,  rating: :good

        docs = ViewTest.find_by_rating(1).collect { |ob|
            ob.name
        }

        expect(Set.new(docs)).to eq(Set.new(['bob', 'jane']))
    end
end
