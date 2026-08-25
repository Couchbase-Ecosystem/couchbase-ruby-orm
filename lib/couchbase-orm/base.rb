# frozen_string_literal: true, encoding: ASCII-8BIT


require 'set'
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
require 'couchbase-orm/json_schema/validation'
require 'couchbase-orm/utilities/properties_always_exists_in_document'

module CouchbaseOrm
    class Document
        include Inspectable
        include ::ActiveModel::Model
        include Changeable
        include ::ActiveModel::Attributes
        include ::ActiveModel::Serializers::JSON

        include ::ActiveModel::Validations
        include ::ActiveModel::Validations::Callbacks

        include ActiveRecordCompat
        include StrictLoading
        include Encrypt

        extend Enum
        extend IgnoredProperties

        define_model_callbacks :initialize, :only => :after

        Metadata = Struct.new(:cas)

        class MismatchTypeError < RuntimeError; end

        # Configuration option to control whether unknown attributes should raise an error
        # Set to false to silently ignore unknown attributes during mass assignment
        class_attribute :raise_on_unknown_attributes, default: true

        # Returns a cached Set of attribute names for efficient lookup
        # This avoids repeated array-to-set conversions in assign_attributes
        def self.attribute_names_set
            @attribute_names_set ||= attribute_names.to_set
        end

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

        # Handle assignment to unknown attributes based on raise_on_unknown_attributes configuration
        # If raise_on_unknown_attributes is false, unknown attributes are silently ignored
        # If raise_on_unknown_attributes is true (default), ActiveModel::UnknownAttributeError is raised
        def attribute_writer_missing(name, value)
            if self.class.raise_on_unknown_attributes
                super
            else
                CouchbaseOrm.logger.warn "Ignoring unknown attribute '#{name}' for #{self.class.name}"
            end
        end

        # Override assign_attributes to filter unknown attributes when raise_on_unknown_attributes is false
        # This ensures consistent behavior across Document and NestedDocument
        def assign_attributes(hash)
            hash = hash.with_indifferent_access if hash.is_a?(Hash)

            if self.class.raise_on_unknown_attributes
                super(hash.except("type"))
            else
                # Filter unknown attributes using cached Set for O(1) lookups
                known_names = self.class.attribute_names
                known_attrs = hash.slice(*known_names)

                # Use cached Set for efficient O(1) lookup of unknown keys
                unknown_keys = hash.keys.reject { |k| self.class.attribute_names_set.include?(k) || k == "type" }

                if unknown_keys.any?
                    CouchbaseOrm.logger.warn "Ignoring unknown attribute(s) for #{self.class.name}: #{unknown_keys.join(', ')}"
                end
                super(known_attrs)
            end
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
        define_model_callbacks :create, :destroy, :save, :update
        include Persistence

        include Associations
        include Views
        include QueryHelper
        include N1ql
        include Relation
        include Timestamps

        extend Join
        extend Enum
        extend EnsureUnique
        extend HasMany
        extend Index
        extend JsonSchema::Validation
        extend PropertiesAlwaysExistsInDocument


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
