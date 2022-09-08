require File.expand_path("../support", __FILE__)


class TypeTest < CouchbaseOrm::Base
    attribute :name, :string
    attribute :age,  :integer
    attribute :size, :float
    attribute :renewale_date, :date
    attribute :subscribed_at, :datetime
    attribute :active, :boolean
    view :all
end

TypeTest.ensure_design_document!

describe CouchbaseOrm::Base do
    before(:each) do
        TypeTest.all.each(&:destroy)
    end

    it "should be createable" do
        t = TypeTest.create!
        expect(t).to be_a(TypeTest)
    end

    it "should be able to set attributes" do
        t = TypeTest.new
        t.name = "joe"
        t.age = 20
        t.size = 1.5
        t.renewale_date = Date.today
        t.subscribed_at = Time.now
        t.active = true
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewale_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to set attributes with a hash" do
        t = TypeTest.new(name: "joe", age: 20, size: 1.5, renewale_date: Date.today, subscribed_at: Time.now, active: true)
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewale_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to set attributes with a hash with indifferent access" do
        t = TypeTest.new(ActiveSupport::HashWithIndifferentAccess.new(name: "joe", age: 20, size: 1.5, renewale_date: Date.today, subscribed_at: Time.now, active: true))
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewale_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to type cast attributes" do
        t = TypeTest.new(name: "joe", age: "20", size: "1.5", renewale_date: Date.today.to_s, subscribed_at: Time.now.to_s, active: "true")
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewale_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be consistent with active record on failed cast" do
        t = TypeTest.new(name: "joe", age: "joe", size: "joe", renewale_date: "joe", subscribed_at: "joe", active: "true")
        t.save!

        expect(t.age).to eq 0
        expect(t.size).to eq 0.0
        expect(t.renewale_date).to eq nil
        expect(t.subscribed_at).to eq nil
        expect(t.active).to eq true
    end
end
