require 'couchbase-orm/utilities/strict'

RSpec.describe CouchbaseOrm::Strict do
  let(:klass) { Class.new { extend CouchbaseOrm::Strict } }

  describe '#strict' do
    it 'defaults to true' do
      expect(klass.strict).to eq(true)
    end
  end

  describe '#strict=' do
    it 'does not mixup strict between classes' do
      other_klass = Class.new { extend CouchbaseOrm::Strict }

      klass.strict = false

      expect(klass.strict).to eq(false)
      expect(other_klass.strict).to eq(true)
    end

    it 'raises when assigned a non-boolean value' do
      expect { klass.strict = 'nope' }.to raise_error(ArgumentError)
    end
  end
end
