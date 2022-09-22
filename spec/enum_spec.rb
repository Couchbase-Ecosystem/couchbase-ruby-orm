# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class EnumTest < CouchbaseOrm::Document
    enum rating: [:awesome, :good, :okay, :bad], default: :okay
    enum color: [:red, :green, :blue]
end

describe CouchbaseOrm::Document do
    it "should create an attribute" do
        base  = EnumTest.create!(rating: :good, color: :red)
        expect(base.attribute_names).to eq(["id", "rating", "color"])
    end

    it "should set the attribute" do
        base  = EnumTest.create!(rating: :good, color: :red)
        expect(base.rating).to_not be_nil
        expect(base.color).to_not be_nil
    end

    it "should convert it to an int" do
        base  = EnumTest.create!(rating: :good, color: :red)
        expect(base.rating).to eq 2
        expect(base.color).to eq 1
    end

    it "should use default value" do
        base  = EnumTest.create!
        expect(base.rating).to eq 3
        expect(base.color).to eq 1
    end
end
       
