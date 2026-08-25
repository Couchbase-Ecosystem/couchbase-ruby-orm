require './lib/couchbase-orm/active_record_compat'

class Foo
  include CouchbaseOrm::ActiveRecordCompat

  def self.attribute_names
    %w[id compute_age]
  end

  def self.attribute_types
    { 'id' => :string }
  end

  def attribute_names
    self.class.attribute_names
  end

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

  describe '.primary_key' do
    it 'is always "id"' do
      expect(Foo.primary_key).to eq('id')
    end
  end

  describe '.base_class?' do
    it 'is always true' do
      expect(Foo.base_class?).to be true
    end
  end

  describe '.column_names' do
    it 'delegates to .attribute_names' do
      expect(Foo.column_names).to eq(%w[id compute_age])
    end
  end

  describe '.abstract_class?' do
    it 'is always false' do
      expect(Foo.abstract_class?).to be false
    end
  end

  describe '.connected?' do
    it 'is always true' do
      expect(Foo.connected?).to be true
    end
  end

  describe '.table_exists?' do
    it 'is always true' do
      expect(Foo.table_exists?).to be true
    end
  end

  describe '._reflect_on_association' do
    it 'is always false' do
      expect(Foo._reflect_on_association(:anything)).to be false
    end
  end

  describe '.type_for_attribute' do
    it 'delegates to .attribute_types' do
      expect(Foo.type_for_attribute('id')).to eq(:string)
    end
  end

  describe '#_has_attribute?' do
    it 'checks membership in #attribute_names' do
      expect(foo._has_attribute?(:compute_age)).to be true
      expect(foo._has_attribute?(:unknown)).to be false
    end
  end

  describe '#attribute_for_inspect' do
    it 'inspects the value returned by the named method' do
      expect(foo.attribute_for_inspect(:compute_age)).to eq('42')
    end
  end
end
