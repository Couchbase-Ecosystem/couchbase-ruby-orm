# frozen_string_literal: true, encoding: ASCII-8BIT


require 'active_model'
require 'active_support/hash_with_indifferent_access'
require 'couchbase'
require 'couchbase-orm/changeable'
require 'couchbase-orm/inspectable'
require 'couchbase-orm/error'
require 'couchbase-orm/views'
require 'couchbase-orm/n1ql'
require 'couchbase-orm/persistence'
require 'couchbase-orm/associations'
require 'couchbase-orm/types'
require 'couchbase-orm/relation'
require 'couchbase-orm/proxies/bucket_proxy'
require 'couchbase-orm/proxies/collection_proxy'
require 'couchbase-orm/utilities/join'
require 'couchbase-orm/utilities/enum'
require 'couchbase-orm/utilities/index'
require 'couchbase-orm/utilities/has_many'
require 'couchbase-orm/utilities/ensure_unique'
require 'couchbase-orm/utilities/query_helper'
require 'couchbase-orm/utilities/ignored_properties'
require 'couchbase-orm/json_transcoder'
require 'couchbase-orm/timestamps'
require 'couchbase-orm/active_record_compat'
require 'couchbase-orm/strict_loading'


module CouchbaseOrm
    class Document
        include Inspectable
        include ::ActiveModel::Model
        include ::ActiveModel::Dirty
        include Changeable # override some methods from ActiveModel::Dirty (keep it included after)
        include ::ActiveModel::Attributes
        include ::ActiveModel::Serializers::JSON

        include ::ActiveModel::Validations
        include ::ActiveModel::Validations::Callbacks

        include ActiveRecordCompat
        include StrictLoading
        include Encrypt

        extend Enum

        define_model_callbacks :initialize, :only => :after

        Metadata = Struct.new(:cas)

        class MismatchTypeError < RuntimeError; end

        def initialize(model = nil, ignore_doc_type: false, **attributes)
            CouchbaseOrm.logger.debug { "Initialize model #{model} with #{attributes.to_s.truncate(200)}" }
            @__metadata__   = Metadata.new

            super()

            if model
                case model
                when Couchbase::Collection::GetResult
                    doc = HashWithIndifferentAccess.new(model.content) || raise('empty response provided')
                    type = doc.delete(:type)
                    doc.delete(:id)

                    if type && !ignore_doc_type && type.to_s != self.class.design_document
                        raise CouchbaseOrm::Error::TypeMismatchError.new("document type mismatch, #{type} != #{self.class.design_document}", self)
                    end

                    self.id = attributes[:id] if attributes[:id].present?
                    @__metadata__.cas = model.cas

                    assign_attributes(decode_encrypted_attributes(doc))
                when CouchbaseOrm::Base
                    clear_changes_information
                    super(model.attributes.except(:id, 'type'))
                else
                    clear_changes_information
                    assign_attributes(decode_encrypted_attributes(**attributes.merge(Hash(model)).symbolize_keys))
                end
            else
                clear_changes_information
                super(attributes)
            end

            yield self if block_given?

            init_strict_loading
            run_callbacks :initialize
        end

        def [](key)
            send(key)
        end

        def []=(key, value)
            send(:"#{key}=", value)
        end

        protected

        def serialized_attributes
            encode_encrypted_attributes.map { |k, v|
                [k, self.class.attribute_types[k].serialize(v)]
            }.to_h
        end
    end

    class NestedDocument < Document
        def initialize(*args, **kwargs)
            super
            if respond_to?(:id) && id.nil?
                assign_attributes(id: SecureRandom.hex)
            end
        end
    end

    class Base < Document
        include Persistence

        include Associations
        include Views
        include QueryHelper
        include N1ql
        include Relation

        extend Join
        extend Enum
        extend EnsureUnique
        extend HasMany
        extend Index
        extend IgnoredProperties

        define_model_callbacks :create, :destroy, :save, :update
        include Timestamps

        class << self

            def attribute(name, ...)
                super
                create_dirty_methods(name, name)
                create_setters(name)
            end

            def connect(**options)
                @bucket = BucketProxy.new(::MTLibcouchbase::Bucket.new(**options))
            end

            def bucket=(bucket)
                @bucket = bucket.is_a?(BucketProxy) ? bucket : BucketProxy.new(bucket)
            end

            def bucket
                @bucket ||= BucketProxy.new(Connection.bucket)
            end

            def cluster
                Connection.cluster
            end

            def collection
                CollectionProxy.new(bucket.default_collection)
            end

            def uuid_generator
                @uuid_generator ||= IdGenerator
            end

            def uuid_generator=(generator)
                @uuid_generator = generator
            end

            def find(*ids, quiet: false, with_strict_loading: false)
                CouchbaseOrm.logger.debug { "Base.find(l##{ids.length}) #{ids}" }

                ids = ids.flatten.select { |id| id.present? }
                if ids.empty?
                    raise CouchbaseOrm::Error::EmptyNotAllowed, 'no id(s) provided'
                end

                transcoder = CouchbaseOrm::JsonTranscoder.new(ignored_properties: ignored_properties)
                records = quiet ? collection.get_multi(ids, transcoder: transcoder) : collection.get_multi!(ids, transcoder: transcoder)
                CouchbaseOrm.logger.debug { "Base.find found(#{records})" }
                records = records.zip(ids).map { |record, id|
                    next unless record
                    next if record.error
                    new(record, id: id).tap do |instance|
                        if with_strict_loading
                            instance.strict_loading!
                        end
                    end.tap(&:reset_object!)
                }.compact
                ids.length > 1 ? records : records[0]
            end

            def find_by_id(*ids, **options)
                options[:quiet] = true
                find(*ids, **options)
            end
            alias_method :[], :find_by_id

            def exists?(id)
                CouchbaseOrm.logger.debug { "Data - Exists? #{id}" }
                collection.exists(id).exists
            end
            alias_method :has_key?, :exists?
        end

        def id=(value)
            raise RuntimeError, 'ID cannot be changed' if @__metadata__.cas && value
            attribute_will_change!(:id)
            _write_attribute("id", value)
        end

        # Public: Allows for access to ActiveModel functionality.
        #
        # Returns self.
        def to_model
            self
        end

        # Public: Hashes identifying properties of the instance
        #
        # Ruby normally hashes an object to be used in comparisons.  In our case
        # we may have two techincally different objects referencing the same entity id.
        #
        # Returns a string representing the unique key.
        def hash
            "#{self.class.name}-#{self.id}-#{@__metadata__.cas}-#{@__attributes__.hash}".hash
        end

        # Public: Overrides eql? to use == in the comparison.
        #
        # other - Another object to compare to
        #
        # Returns a boolean.
        def eql?(other)
            self == other
        end

        # Public: Overrides == to compare via class and entity id.
        #
        # other - Another object to compare to
        #
        # Returns a boolean.
        def ==(other)
            super || other.instance_of?(self.class) && !id.nil? && other.id == id
        end
    end
end
