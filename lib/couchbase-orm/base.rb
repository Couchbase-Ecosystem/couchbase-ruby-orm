# frozen_string_literal: true, encoding: ASCII-8BIT


require 'active_model'
require 'active_support/hash_with_indifferent_access'
require 'couchbase'
require 'couchbase-orm/error'
require 'couchbase-orm/views'
require 'couchbase-orm/n1ql'
require 'couchbase-orm/persistence'
require 'couchbase-orm/associations'
require 'couchbase-orm/proxies/bucket_proxy'
require 'couchbase-orm/proxies/collection_proxy'
require 'couchbase-orm/utilities/join'
require 'couchbase-orm/utilities/enum'
require 'couchbase-orm/utilities/index'
require 'couchbase-orm/utilities/has_many'
require 'couchbase-orm/utilities/ensure_unique'


module CouchbaseOrm
    class Base
        include ::ActiveModel::Model
        include ::ActiveModel::Dirty
        include ::ActiveModel::Serializers::JSON

        include ::ActiveModel::Validations
        include ::ActiveModel::Validations::Callbacks
        define_model_callbacks :initialize, :only => :after
        define_model_callbacks :create, :destroy, :save, :update

        include Persistence
        include Associations
        include Views
        include N1ql

        extend Join
        extend Enum
        extend EnsureUnique
        extend HasMany
        extend Index


        Metadata = Struct.new(:key, :cas)


        class << self
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

            def attribute(*names, **options)
                @attributes ||= {}
                names.each do |name|
                    name = name.to_sym

                    @attributes[name] = options

                    unless self.instance_methods.include?(name)
                        define_method(name) do
                            read_attribute(name)
                        end
                    end

                    eq_meth = :"#{name}="
                    unless self.instance_methods.include?(eq_meth)
                        define_method(eq_meth) do |value|
                            value = yield(value) if block_given?
                            write_attribute(name, value)
                        end
                    end
                end
            end

            def attributes
                @attributes ||= {}
            end

            def find(*ids, quiet: false)
                CouchbaseOrm.logger.debug { "Base.find(l##{ids.length}) #{ids}" }

                ids = ids.flatten.select { |id| id.present? }
                if ids.empty?
                    raise CouchbaseOrm::Error::EmptyNotAllowed, 'no id(s) provided'
                end

                records = quiet ? collection.get_multi(ids) : collection.get_multi!(ids)
                CouchbaseOrm.logger.debug { "Base.find found(#{records})" }
                records = records.zip(ids).map { |record, id|
                    self.new(record, id: id) if record
                }
                records.compact!
                ids.length > 1 ? records : records[0]
            end

            def find_by_id(*ids, **options)
                options[:quiet] = true
                find(*ids, **options)
            end
            alias_method :[], :find_by_id

            def exists?(id)
                CouchbaseOrm.logger.debug "Data - Exists? #{id}"
                collection.exists(id).exists
            end
            alias_method :has_key?, :exists?
        end

        class MismatchTypeError < RuntimeError; end

        # Add support for libcouchbase response objects
        def initialize(model = nil, ignore_doc_type: false, **attributes)
            @__metadata__   = Metadata.new

            # Assign default values
            @__attributes__ = ::ActiveSupport::HashWithIndifferentAccess.new({type: self.class.design_document})
            self.class.attributes.each do |key, options|
                default = options[:default]
                if default.respond_to?(:call)
                    write_attribute key, default.call
                else
                    write_attribute key, default
                end
            end

            if model
                case model
                when Couchbase::Collection::GetResult
                    CouchbaseOrm.logger.debug "Initialize with Couchbase::Collection::GetResult"
                    doc = model.content || raise('empty response provided')
                    type = doc.delete('type')
                    doc.delete(:id)

                    if type && !ignore_doc_type && type.to_s != self.class.design_document
                        raise CouchbaseOrm::Error::TypeMismatchError.new("document type mismatch, #{type} != #{self.class.design_document}", self)
                    end

                    @__metadata__.key = attributes[:id]
                    @__metadata__.cas = model.cas

                    # This ensures that defaults are applied
                    @__attributes__.merge! doc
                when CouchbaseOrm::Base
                    CouchbaseOrm.logger.debug "Initialize with CouchbaseOrm::Base"

                    clear_changes_information
                    attributes = model.attributes
                    attributes.delete(:id)
                    attributes.delete('type')
                    super(attributes)
                else
                    clear_changes_information
                    super(attributes.merge(Hash(model)))
                end
            else
                clear_changes_information
                super(attributes)
            end

            yield self if block_given?

            run_callbacks :initialize
        end


        # Document ID is a special case as it is not stored in the document
        def id
            @__metadata__.key || @id
        end

        def id=(value)
            raise 'ID cannot be changed' if @__metadata__.cas
            attribute_will_change!(:id)
            @id = value.to_s
        end

        def read_attribute(attr_name)
            read_fn = self.class.attributes[attr_name][:read_fn]
            value = @__attributes__[attr_name]
            value = read_fn.call(value) if read_fn
            value
        end
        alias_method :[], :read_attribute

        def write_attribute(attr_name, value)
            unless value.nil?
                coerce = self.class.attributes[attr_name][:type]
                value = Kernel.send(coerce.to_s, value) if coerce
            end
            attribute_will_change!(attr_name) unless @__attributes__[attr_name] == value
            @__attributes__[attr_name] = value
        end
        alias_method :[]=, :write_attribute

        #
        # Add support for Serialization:
        # http://guides.rubyonrails.org/active_model_basics.html#serialization
        #

        def attributes
            copy = @__attributes__.merge({id: id})
            copy.delete(:type)
            copy
        end

        def attributes=(attributes)
            attributes.each do |key, value|
                setter = :"#{key}="
                send(setter, value) if respond_to?(setter)
            end
        end

        ID_LOOKUP = ['id', :id].freeze
        def attribute(name)
            return self.id if ID_LOOKUP.include?(name)
            @__attributes__[name]
        end
        alias_method :read_attribute_for_serialization, :attribute

        def attribute=(name, value)
            __send__(:"#{name}=", value)
        end


        #
        # Add support for comparisons
        #

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
            case other
            when self.class
                hash == other.hash
            else
                false
            end
        end
    end
end
