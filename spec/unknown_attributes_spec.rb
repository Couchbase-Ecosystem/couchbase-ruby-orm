# frozen_string_literal: true, encoding: ASCII-8BIT

require File.expand_path("../support", __FILE__)

# A minimal stand-in for ActionController::Parameters (each_pair/each/except,
# no #to_hash). Real Parameters would work too, but pulling in actionpack
# here would make this spec's outcome depend on whatever version bundler
# happens to resolve it to; what actually matters is that the filter is
# guarded by `respond_to?(:each_pair)`, not `is_a?(Hash)`.
#
# `each` is required too, not just `each_pair`: ActiveModel::AttributeAssignment's
# own `_assign_attributes` (which our `super` eventually reaches) iterates via
# `.each` on ActiveModel < 8.0, and via `.each_pair` on 8.0+.
class EachPairOnly
    def initialize(hash)
        @hash = hash
    end

    def each_pair(&block)
        @hash.each_pair(&block)
    end
    alias_method :each, :each_pair

    def except(*keys)
        EachPairOnly.new(@hash.except(*keys))
    end

    def empty?
        @hash.empty?
    end
end

class UnknownAttrsStrict < CouchbaseOrm::Base
    attribute :name, :string
end

class UnknownAttrsTolerant < CouchbaseOrm::Base
    self.raise_on_unknown_attributes = false
    attribute :name, :string
    attribute :secret, :encrypted
end

class UnknownAttrsTolerantChild < UnknownAttrsTolerant
end

class UnknownAttrsBoth < CouchbaseOrm::Base
    self.raise_on_unknown_attributes = false
    self.ignored_properties = [:legacy_ignored]
    attribute :name, :string
end

class UnknownAttrsAssocParent < CouchbaseOrm::Base
    attribute :name, :string
end

class UnknownAttrsAssocChild < CouchbaseOrm::Base
    self.raise_on_unknown_attributes = false
    attribute :name, :string
    belongs_to :unknown_attrs_assoc_parent, dependent: :destroy
end

RSpec.describe "raise_on_unknown_attributes" do
    # No public reset API on purpose (it would be test-only surface on
    # production code) - reach into the module's own warn-once tracking
    # directly so these examples don't depend on run order.
    before { CouchbaseOrm::UnknownAttributes.instance_variable_get(:@warned).clear }

    describe "defaults" do
        it "defaults to true" do
            expect(CouchbaseOrm::Base.raise_on_unknown_attributes).to be true
            expect(UnknownAttrsStrict.raise_on_unknown_attributes).to be true
        end

        it "still raises ActiveModel::UnknownAttributeError when true" do
            expect { UnknownAttrsStrict.new(name: 'bob', nope: 'x') }.to raise_error(ActiveModel::UnknownAttributeError)
            model = UnknownAttrsStrict.new(name: 'bob')
            expect { model.assign_attributes(nope: 'x') }.to raise_error(ActiveModel::UnknownAttributeError)
        end
    end

    describe "inheritance" do
        it "is inherited by subclasses, unlike ignored_properties" do
            expect(UnknownAttrsTolerantChild.raise_on_unknown_attributes).to be false
        end

        it "does not leak from a subclass back to its parent or to Base" do
            expect(UnknownAttrsTolerant.raise_on_unknown_attributes).to be false
            expect(CouchbaseOrm::Base.raise_on_unknown_attributes).to be true
        end
    end

    describe "association writers are not treated as unknown attributes" do
        it "still resolves belongs_to via its writer, not via attribute_names" do
            parent = UnknownAttrsAssocParent.create!(name: 'parent')
            child = UnknownAttrsAssocChild.new(name: 'child', unknown_attrs_assoc_parent: parent, really_unknown: 'x')

            expect(child.unknown_attrs_assoc_parent_id).to eq(parent.id)
            expect(child.respond_to?(:really_unknown)).to be false
        end
    end

    describe "given a document with an unknown property" do
        let(:doc_id) { "unknown_attrs_tolerant_#{SecureRandom.hex}" }
        let(:document_properties) do
            {
                'type' => UnknownAttrsTolerant.design_document,
                'name' => 'Alice',
                'server_encrypted_content' => 'not yet known to this code'
            }
        end

        before { UnknownAttrsTolerant.bucket.default_collection.upsert doc_id, document_properties }
        after { UnknownAttrsTolerant.bucket.default_collection.remove doc_id }

        it "does not raise on find (the INC-5405 path) and drops the unknown key" do
            model = UnknownAttrsTolerant.find(doc_id)
            expect(model.name).to eq('Alice')
            expect(model.attributes.keys).not_to include('server_encrypted_content')
        end

        it "raises on find when raise_on_unknown_attributes is true" do
            document_properties['type'] = UnknownAttrsStrict.design_document
            UnknownAttrsStrict.bucket.default_collection.upsert doc_id, document_properties
            expect { UnknownAttrsStrict.find(doc_id) }.to raise_error(ActiveModel::UnknownAttributeError)
        end

        it "does not raise on reload" do
            model = UnknownAttrsTolerant.find(doc_id)
            expect { model.reload }.not_to raise_error
            expect(model.attributes.keys).not_to include('server_encrypted_content')
        end

        it "logs a warning exactly once per (class, key), and debug on every call" do
            allow(CouchbaseOrm.logger).to receive(:debug).and_call_original
            expect(CouchbaseOrm.logger).to receive(:warn).once.with(a_string_including('server_encrypted_content'))

            UnknownAttrsTolerant.find(doc_id)
            UnknownAttrsTolerant.find(doc_id)
        end

        it "emits no warning at all when raise_on_unknown_attributes is true" do
            document_properties['type'] = UnknownAttrsStrict.design_document
            UnknownAttrsStrict.bucket.default_collection.upsert doc_id, document_properties
            expect(CouchbaseOrm.logger).not_to receive(:warn)
            expect { UnknownAttrsStrict.find(doc_id) }.to raise_error(ActiveModel::UnknownAttributeError)
        end

        it "drops the unknown key from the stored document on the next save (same trade-off as ignored_properties)" do
            model = UnknownAttrsTolerant.find(doc_id)
            model.name = 'Alice Updated'
            expect { model.save! }.to change {
                UnknownAttrsTolerant.bucket.default_collection.get(doc_id).content.keys.sort
            }.from(%w[name server_encrypted_content type]).to(%w[name type])
        end
    end

    describe "interaction with encrypted$-prefixed keys" do
        it "tolerates an unknown key that only happens to carry the encrypted$ prefix" do
            doc_id = "unknown_attrs_tolerant_enc_#{SecureRandom.hex}"
            UnknownAttrsTolerant.bucket.default_collection.upsert doc_id, {
                'type' => UnknownAttrsTolerant.design_document,
                'name' => 'Bob',
                'encrypted$tanker_encrypted_content' => { 'alg' => 'tanker', 'ciphertext' => 'legacy' }
            }

            model = UnknownAttrsTolerant.find(doc_id)
            expect(model.name).to eq('Bob')
            expect(model.attributes.keys).not_to include('tanker_encrypted_content', 'encrypted$tanker_encrypted_content')
        ensure
            UnknownAttrsTolerant.bucket.default_collection.remove doc_id
        end
    end

    describe "combined with ignored_properties" do
        let(:doc_id) { "unknown_attrs_both_#{SecureRandom.hex}" }

        before do
            UnknownAttrsBoth.bucket.default_collection.upsert doc_id, {
                'type' => UnknownAttrsBoth.design_document,
                'name' => 'Carol',
                'legacy_ignored' => 'handled by ignored_properties',
                'other_unknown' => 'handled by the flag'
            }
        end
        after { UnknownAttrsBoth.bucket.default_collection.remove doc_id }

        it "tolerates both without raising, and only warns about the one the flag handled" do
            expect(CouchbaseOrm.logger).to receive(:warn).once.with(a_string_including('other_unknown'))
            model = UnknownAttrsBoth.find(doc_id)
            expect(model.name).to eq('Carol')
            expect(model.attributes.keys).not_to include('legacy_ignored', 'other_unknown')
        end
    end

    describe "duck-typed, non-Hash input (e.g. ActionController::Parameters)" do
        it "filters through a respond_to?(:each_pair) object just like a Hash" do
            # Calling assign_attributes directly (rather than .new) matters here:
            # Document#initialize's generic branch runs every non-GetResult,
            # non-CouchbaseOrm::Base argument through Kernel#Hash(), which would
            # coerce a real permitted ActionController::Parameters (it defines
            # #to_hash) before assign_attributes ever saw it - masking exactly
            # the guard this test means to exercise.
            model = UnknownAttrsTolerant.new(name: 'Dave')
            model.assign_attributes(EachPairOnly.new(name: 'Dave Updated', nope: 'x'))
            expect(model.name).to eq('Dave Updated')
            expect(model.respond_to?(:nope)).to be false
        end

        it "still raises for a non-Hash, non-each_pair argument, same as before this feature existed" do
            # Persistence#assign_attributes (unrelated to raise_on_unknown_attributes,
            # pre-existing on CouchbaseOrm::Base) calls `hash.except("type")`
            # unconditionally, so on Base this is a NoMethodError rather than the
            # ArgumentError plain ActiveModel would raise. Either way, it must not
            # be silently swallowed by the unknown-attributes filter.
            expect { UnknownAttrsTolerant.new.assign_attributes(Object.new) }.to raise_error(StandardError)
        end
    end

    describe "attributes=" do
        it "goes through the same filtering as assign_attributes" do
            model = UnknownAttrsTolerant.new(name: 'Eve')
            model.attributes = { name: 'Eve Updated', nope: 'x' }
            expect(model.name).to eq('Eve Updated')
            expect(model.respond_to?(:nope)).to be false
        end
    end
end
