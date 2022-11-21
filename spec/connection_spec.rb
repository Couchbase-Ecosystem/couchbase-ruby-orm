# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

class ConnectedModel < CouchbaseOrm::Base
  attribute :name, :string
end

# disabled by default because a little hacky
# and test couchbase ruby client not couchbase orm

return unless ENV["TEST_DOCKER_CONTAINER"]

describe CouchbaseOrm::Base do
    it "should reconnect after a disconnection" do
      s = ConnectedModel.create!(name: "foo")
      `docker stop #{ENV["TEST_DOCKER_CONTAINER"]}`
      sleep 3
      expect {ConnectedModel.find(s.id)}.to raise_error(Couchbase::Error::UnambiguousTimeout)
      `docker start #{ENV["TEST_DOCKER_CONTAINER"]}`
      sleep 10
      s2 = ConnectedModel.find(s.id)
      expect(s2.name).to eq (s.name)
    ensure
      `docker start #{ENV["TEST_DOCKER_CONTAINER"]}`
    end
end
