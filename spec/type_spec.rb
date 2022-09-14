require File.expand_path("../support", __FILE__)

require "active_model"

class DateTimeWith3Decimal < CouchbaseOrm::Types::DateTime
  def serialize(value)
    value&.iso8601(3)
  end
end

ActiveModel::Type.register(:datetime3decimal, DateTimeWith3Decimal)

class TypeTest < CouchbaseOrm::Base
    attribute :name, :string
    attribute :age,  :integer
    attribute :size, :float
    attribute :renewal_date, :date
    attribute :subscribed_at, :datetime
    attribute :some_time, :timestamp
    attribute :precision_time, :datetime3decimal
    attribute :active, :boolean

    n1ql :all

    index :age, presence: false
    index :renewal_date, presence: false
    index :some_time, presence: false
    index :precision_time, presence: false
end

class N1qlTypeTest < CouchbaseOrm::Base
    attribute :name, :string
    attribute :age,  :integer
    attribute :size, :float
    attribute :renewal_date, :date
    attribute :subscribed_at, :datetime
    attribute :some_time, :timestamp
    attribute :precision_time, :datetime3decimal
    attribute :active, :boolean

    n1ql :all

    index_n1ql :name, validate: false
    index_n1ql :age, validate: false
    index_n1ql :size, validate: false
    index_n1ql :active, validate: false
    index_n1ql :renewal_date, validate: false
    index_n1ql :some_time, validate: false
    index_n1ql :subscribed_at, validate: false
    index_n1ql :precision_time, validate: false
    n1ql :by_both_dates, emit_key: [:renewal_date, :subscribed_at], presence: false
end

TypeTest.ensure_design_document!
N1qlTypeTest.ensure_design_document!

describe CouchbaseOrm::Types::Timestamp do
    it "should cast an integer to time" do
        t = Time.at(Time.now.to_i)
        expect(CouchbaseOrm::Types::Timestamp.new.cast(t.to_i)).to eq(t)
    end
    it "should cast an integer string to time" do
        t = Time.at(Time.now.to_i)
        expect(CouchbaseOrm::Types::Timestamp.new.cast(t.to_s)).to eq(t)
    end
end

describe CouchbaseOrm::Base do
    before(:each) do
        TypeTest.all.each(&:destroy)
        N1qlTypeTest.all.each(&:destroy)
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
        t.renewal_date = Date.today
        t.subscribed_at = Time.now
        t.active = true
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewal_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to set attributes with a hash" do
        t = TypeTest.new(name: "joe", age: 20, size: 1.5, renewal_date: Date.today, subscribed_at: Time.now, active: true)
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewal_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to be stored and retrieved" do
        now = Time.now
        t = TypeTest.create!(name: "joe", age: 20, size: 1.5, renewal_date: Date.today, subscribed_at: now, active: true)
        t2 = TypeTest.find(t.id)

        expect(t2.name).to eq("joe")
        expect(t2.age).to eq(20)
        expect(t2.size).to eq(1.5)
        expect(t2.renewal_date).to eq(Date.today)
        expect(t2.subscribed_at).to eq(now.utc.change(usec: 0))
        expect(t2.active).to eq(true)
    end

    it "should be able to query by age" do
        t = TypeTest.create!(age: 20)
        _t2 = TypeTest.create!(age: 40)
        expect(TypeTest.find_by_age(20)).to eq t
    end

    it "should be able to query by age and type cast" do
        t = TypeTest.create!(age: "20")
        expect(TypeTest.find_by_age(20)).to eq t
        expect(TypeTest.find_by_age("20")).to eq t
    end

    it "should be able to query by date" do
        t = TypeTest.create!(renewal_date: Date.today)
        _t2 = TypeTest.create!(renewal_date: Date.today + 1)
        expect(TypeTest.find_by_renewal_date(Date.today)).to eq t
    end

    it "should be able to query by date and type cast" do
        t = TypeTest.create!(renewal_date: Date.today.to_s)
        expect(TypeTest.find_by_renewal_date(Date.today)).to eq t
        expect(TypeTest.find_by_renewal_date(Date.today.to_s)).to eq t
    end

    it "should be able to query by time" do
        now = Time.now
        t = TypeTest.create!(name: "t", some_time: now)
        _t2 = TypeTest.create!(name: "t2", some_time: now + 1)
        expect(TypeTest.find_by_some_time(now)).to eq t
        binding.pry
    end

    it "should be able to query by time and type cast" do
        now = Time.now
        now_s = now.to_i.to_s
        t = TypeTest.create!(some_time: now_s)
        expect(TypeTest.find_by_some_time(now)).to eq t
        expect(TypeTest.find_by_some_time(now_s)).to eq t
    end

    it "should be able to query by custom type" do
        now = Time.now
        t = TypeTest.create!(precision_time: now)
        _t2 = TypeTest.create!(precision_time: now + 1)
        expect(TypeTest.find_by_precision_time(now)).to eq t
    end

    it "should be able to query by custom type and type cast" do
        now = Time.now
        now_s = now.utc.iso8601(3)
        t = TypeTest.create!(precision_time: now_s)
        expect(TypeTest.find_by_precision_time(now)).to eq t
        expect(TypeTest.find_by_precision_time(now_s)).to eq t
    end

    it "should be able to set attributes with a hash with indifferent access" do
        t = TypeTest.new(ActiveSupport::HashWithIndifferentAccess.new(name: "joe", age: 20, size: 1.5, renewal_date: Date.today, subscribed_at: Time.now, active: true))
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewal_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be able to type cast attributes" do
        t = TypeTest.new(name: "joe", age: "20", size: "1.5", renewal_date: Date.today.to_s, subscribed_at: Time.now.to_s, active: "true")
        t.save!

        expect(t.name).to eq("joe")
        expect(t.age).to eq(20)
        expect(t.size).to eq(1.5)
        expect(t.renewal_date).to eq(Date.today)
        expect(t.subscribed_at).to be_a(Time)
        expect(t.active).to eq(true)
    end

    it "should be consistent with active record on failed cast" do
        t = TypeTest.new(name: "joe", age: "joe", size: "joe", renewal_date: "joe", subscribed_at: "joe", active: "true")
        t.save!

        expect(t.age).to eq 0
        expect(t.size).to eq 0.0
        expect(t.renewal_date).to eq nil
        expect(t.subscribed_at).to eq nil
        expect(t.active).to eq true
    end

    it "should be able to query by name" do
        t = N1qlTypeTest.create!(name: "joe")
        _t2 = N1qlTypeTest.create!(name: "john")
        expect(N1qlTypeTest.find_by_name("joe").to_a).to eq [t]
    end

    pending "should be able to query by nil value" do
        t = N1qlTypeTest.create!()
        _t2 = N1qlTypeTest.create!(name: "john")
        expect(N1qlTypeTest.find_by_name(nil).to_a).to eq [t]
    end
    
    pending "should be able to query by array value" do
        t = N1qlTypeTest.create!(name: "laura")
        t2 = N1qlTypeTest.create!(name: "joe")
        _t3 = N1qlTypeTest.create!(name: "john")
        expect(N1qlTypeTest.find_by_name(["laura", "joe"]).to_a).to match_array [t, t2]
    end

    it "should be able to query by integer" do
        t = N1qlTypeTest.create!(age: 20)
        t2 = N1qlTypeTest.create!(age: 20)
        _t3 = N1qlTypeTest.create!(age: 40)
        expect(N1qlTypeTest.find_by_age(20).to_a).to match_array [t, t2]
    end

    it "should be able to query by integer and type cast" do
        t = N1qlTypeTest.create!(age: "20")
        expect(N1qlTypeTest.find_by_age(20).to_a).to eq [t]
        expect(N1qlTypeTest.find_by_age("20").to_a).to eq [t]
    end

    it "should be able to query by date" do
        t = N1qlTypeTest.create!(renewal_date: Date.today)
        _t2 = N1qlTypeTest.create!(renewal_date: Date.today + 1)
        expect(N1qlTypeTest.find_by_renewal_date(Date.today).to_a).to eq [t]
    end

    it "should be able to query by datetime" do
        now = Time.now
        t = N1qlTypeTest.create!(subscribed_at: now)
        _t2 = N1qlTypeTest.create!(subscribed_at: now + 1)
        expect(N1qlTypeTest.find_by_subscribed_at(now).to_a).to eq [t]
    end

    it "should be able to query by timestamp" do
        now = Time.now
        t = N1qlTypeTest.create!(some_time: now)
        _t2 = N1qlTypeTest.create!(some_time: now + 1)
        expect(N1qlTypeTest.find_by_some_time(now).to_a).to eq [t]
    end

    it "should be able to query by custom type" do
        now = Time.now
        t = N1qlTypeTest.create!(precision_time: now)
        _t2 = N1qlTypeTest.create!(precision_time: now + 1)
        expect(N1qlTypeTest.find_by_precision_time(now).to_a).to eq [t]
    end

    it "should be able to query by boolean" do
        t = N1qlTypeTest.create!(active: true)
        _t2 = N1qlTypeTest.create!(active: false)
        expect(N1qlTypeTest.find_by_active(true).to_a).to eq [t]      
    end

    it "should be able to query by float" do
        t = N1qlTypeTest.create!(size: 1.5)
        _t2 = N1qlTypeTest.create!(size: 2.5)
        expect(N1qlTypeTest.find_by_size(1.5).to_a).to eq [t]
    end
end
