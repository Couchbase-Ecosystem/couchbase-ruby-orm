require './lib/couchbase-orm/active_record_compat'

class Foo
  include CouchbaseOrm::ActiveRecordCompat

  def compute_age
    10 + 32
  end
end

describe CouchbaseOrm::ActiveRecordCompat do
  let(:foo) { Foo.new }
  describe '#slice' do
    it 'creates a hash with method names as keys and results as values' do
      expect(foo.slice(:compute_age).to_h).to eq(HashWithIndifferentAccess.new({ compute_age: 42 }))
    end
  end

  describe '#values_at' do
    it 'creates an array of results from given method names' do
      expect(foo.values_at([:compute_age])).to eq([42])
    end
  end
end
