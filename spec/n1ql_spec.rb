# frozen_string_literal: true

require File.expand_path("../support", __FILE__)

class N1QLTest < CouchbaseOrm::Base
    attribute :name, type: String
    attribute :lastname, type: String
    enum rating: [:awesome, :good, :okay, :bad], default: :okay

    n1ql :by_custom_rating, emit_key: [:rating], query_fn: proc { |bucket, _values, options|
        cluster.query("SELECT raw meta().id FROM `#{bucket.name}` WHERE type = 'n1_ql_test' AND rating IN [1, 2] ORDER BY name ASC", options)
    }
    n1ql :by_name, emit_key: [:name]
    n1ql :by_lastname, emit_key: [:lastname]
    n1ql :by_rating_emit, emit_key: :rating

    n1ql :by_custom_rating_values, emit_key: [:rating], query_fn: proc { |bucket, values, options|
        cluster.query("SELECT raw meta().id FROM `#{bucket.name}` where type = 'n1_ql_test' AND rating IN #{quote(values[0])} ORDER BY name ASC", options)
    }
    n1ql :by_rating_reverse, emit_key: :rating, custom_order: "name DESC"
    n1ql :by_rating_without_docs, emit_key: :rating, include_docs: false

    # This generates both:
    # view :by_rating, emit_key: :rating
    # def self.find_by_rating(rating); end  # also provide this helper function
    index_n1ql :rating
end

describe CouchbaseOrm::N1ql do
    before(:each) do
        N1QLTest.delete_all
    end
    
    it "should not allow n1ql to override existing methods" do
        expect { N1QLTest.n1ql :all }.to raise_error(ArgumentError)
    end

    it "should perform a query and return the n1ql" do
        N1QLTest.create! name: :bob
        docs = N1QLTest.all.collect { |ob|
            ob.name
        }
        expect(docs).to eq(%w[bob])
    end

    it "should query by non-nil value" do
        _anonymous = N1QLTest.create!
        bob = N1QLTest.create! name: :bob

        expect(N1QLTest.by_name(key: 'bob').to_a).to eq [bob]
    end

    it "should query by nil value" do
        anonymous = N1QLTest.create! lastname: "Anonymous"
        anonymous_no_property = N1QLTest.create! lastname: "Anonymous without name property"

        CouchbaseOrm::Connection.bucket.default_collection.mutate_in(anonymous_no_property.id, [
            Couchbase::MutateInSpec.remove("name"),
        ])

        anonymous_no_property.reload

        _bob = N1QLTest.create! name: :bob

        expect(N1QLTest.by_name(key: nil).to_a).to match_array [anonymous, anonymous_no_property]
    end

    it "should query all when key is not set" do
        anonymous = N1QLTest.create!
        bob = N1QLTest.create! name: :bob

        expect(N1QLTest.by_name.to_a).to eq [anonymous, bob]
    end


    it "should work with other keys" do
        N1QLTest.create! name: :bob, rating: :good
        N1QLTest.create! name: :jane, rating: :awesome
        N1QLTest.create! name: :greg, rating: :bad

        docs = N1QLTest.by_name(descending: true).collect { |ob|
            ob.name
        }
        expect(docs).to eq(%w[jane greg bob])

        docs = N1QLTest.by_rating(descending: true).collect { |ob|
            ob.rating
        }
        expect(docs).to eq([4, 2, 1])
    end

    it "should return matching results" do
        N1QLTest.create! name: :bob, rating: :awesome
        N1QLTest.create! name: :jane, rating: :awesome
        N1QLTest.create! name: :greg, rating: :bad
        N1QLTest.create! name: :mel, rating: :good

        docs = N1QLTest.find_by_rating(1).collect { |ob|
            ob.name
        }

        expect(Set.new(docs)).to eq(Set.new(%w[bob jane]))

        docs = N1QLTest.by_custom_rating().collect { |ob|
            ob.name
        }

        expect(Set.new(docs)).to eq(Set.new(%w[bob jane mel]))
    end

    it "should return matching results with reverse order" do
        N1QLTest.create! name: :bob, rating: :awesome
        N1QLTest.create! name: :jane, rating: :awesome
        N1QLTest.create! name: :greg, rating: :bad
        N1QLTest.create! name: :mel, rating: :good

        docs = N1QLTest.by_rating_reverse(key: 1).collect { |ob|
            ob.name
        }

        expect(docs).to eq(%w[jane bob])
    end

    it "should return matching results without full documents" do
        inst_bob = N1QLTest.create! name: :bob, rating: :awesome
        inst_jane = N1QLTest.create! name: :jane, rating: :awesome
        N1QLTest.create! name: :greg, rating: :bad
        N1QLTest.create! name: :mel, rating: :good

        docs = N1QLTest.by_rating_without_docs(key: 1)

        expect(Set.new(docs)).to eq(Set.new([inst_bob.id, inst_jane.id]))
    end

    it "should return matching results with nil usage" do
        N1QLTest.create! name: :bob, lastname: nil
        N1QLTest.create! name: :jane, lastname: "dupond"

        docs = N1QLTest.by_lastname(key: [nil]).collect { |ob|
            ob.name
        }
        expect(docs).to eq(%w[bob])
    end

    it "should allow storing quoting chars" do
        special_name = "O'Leary & Sons \"The best\" \\ between backslash \\"
        t = N1QLTest.create! name: special_name, rating: :awesome
        expect(N1QLTest.find(t.id).name).to eq(special_name)
        expect(N1QLTest.by_name(key: special_name).to_a.first).to eq(t)
        expect(N1QLTest.where(name: special_name).to_a.first).to eq(t)
        puts N1QLTest.where(name: special_name).to_n1ql
    end
    it "should return matching results with custom n1ql query" do
        N1QLTest.create! name: :bob, rating: :awesome
        N1QLTest.create! name: :jane, rating: :awesome
        N1QLTest.create! name: :greg, rating: :bad
        N1QLTest.create! name: :mel, rating: :good


        docs = N1QLTest.by_custom_rating().collect { |ob|
            ob.name
        }

        expect(Set.new(docs)).to eq(Set.new(%w[bob jane mel]))

        docs = N1QLTest.by_custom_rating_values(key: [[1, 2]]).collect { |ob|
            ob.name
        }

        expect(Set.new(docs)).to eq(Set.new(%w[bob jane mel]))
    end

    it "should log the default scan_consistency when n1ql query is executed" do
        allow(CouchbaseOrm.logger).to receive(:debug)
        N1QLTest.by_rating_reverse()
        expect(CouchbaseOrm.logger).to have_received(:debug).at_least(:once).with('N1QL query: select raw meta().id from `billeo-cb-bucket` where type="n1_ql_test"  order by name DESC  return 0 rows with scan_consistency : request_plus')
    end

    it "should log the set scan_consistency when n1ql query is executed with a specific scan_consistency" do
        allow(CouchbaseOrm.logger).to receive(:debug)
        default_n1ql_config = CouchbaseOrm::N1ql.config
        CouchbaseOrm::N1ql.config({ scan_consistency: :not_bounded })
        N1QLTest.by_rating_reverse()
        expect(CouchbaseOrm.logger).to have_received(:debug).at_least(:once).with("N1QL query: select raw meta().id from `#{CouchbaseOrm::Connection.bucket.name}` where type=\"n1_ql_test\"  order by name DESC  return 0 rows with scan_consistency : not_bounded")

        CouchbaseOrm::N1ql.config(default_n1ql_config)
        N1QLTest.by_rating_reverse()
        expect(CouchbaseOrm.logger).to have_received(:debug).at_least(:once).with("N1QL query: select raw meta().id from `#{CouchbaseOrm::Connection.bucket.name}` where type=\"n1_ql_test\"  order by name DESC  return 0 rows with scan_consistency : request_plus")
    end

    after(:all) do
        N1QLTest.delete_all
    end
end
