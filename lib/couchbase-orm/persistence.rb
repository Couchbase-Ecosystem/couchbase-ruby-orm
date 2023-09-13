# frozen_string_literal: true, encoding: ASCII-8BIT

require 'active_model'
require 'active_support/hash_with_indifferent_access'
require 'couchbase-orm/json_transcoder'

module CouchbaseOrm
    module Persistence
        extend ActiveSupport::Concern

        include Encrypt

        included do
            attribute :id, :string
        end

        module ClassMethods
            def create(attributes = nil, &block)
                if attributes.is_a?(Array)
                    attributes.collect { |attr| create(attr, &block) }
                else
                    instance = new(attributes, &block)
                    instance.save
                    instance
                end
            end

            def create!(attributes = nil, &block)
                if attributes.is_a?(Array)
                    attributes.collect { |attr| create!(attr, &block) }
                else
                    instance = new(attributes, &block)
                    instance.save!
                    instance
                end
            end

            # Raise an error if validation failed.
            def fail_validate!(document)
                raise Error::RecordInvalid.new("Failed to save the record", document)
            end

            # Allow classes to overwrite the default document name
            # extend ActiveModel::Naming (included by ActiveModel::Model)
            def design_document(name = nil)
                return @design_document unless name
                @design_document = name.to_s
            end

            # Set a default design document
            def inherited(child)
                super
                child.instance_eval do
                    @design_document = child.name.underscore
                end
            end
        end


        # Returns true if this object hasn't been saved yet -- that is, a record
        # for the object doesn't exist in the database yet; otherwise, returns false.
        def new_record?
            @__metadata__.cas.nil?
        end
        alias_method :new?, :new_record?

        # Returns true if this object has been destroyed, otherwise returns false.
        def destroyed?
            @destroyed
        end

        # Returns true if the record is persisted, i.e. it's not a new record and it was
        # not destroyed, otherwise returns false.
        def persisted?
            !new_record? && !destroyed?
        end
        alias_method :exists?, :persisted?

        # Saves the model.
        #
        # If the model is new, a record gets created in the database, otherwise
        # the existing record gets updated.
        def save(**options)
            raise "Cannot save a destroyed document!" if destroyed?
            self.new_record? ? _create_record(**options) : _update_record(**options)
        end

        # Saves the model.
        #
        # If the model is new, a record gets created in the database, otherwise
        # the existing record gets updated.
        #
        # By default, #save! always runs validations. If any of them fail
        # CouchbaseOrm::Error::RecordInvalid gets raised, and the record won't be saved.
        def save!(**options)
            self.class.fail_validate!(self) unless self.save(**options)
            self
        end

        # Deletes the record in the database and freezes this instance to
        # reflect that no changes should be made (since they can't be
        # persisted). Returns the frozen instance.
        #
        # The record is simply removed, no callbacks are executed.
        def delete(with_cas: false, **options)
            options[:cas] = @__metadata__.cas if with_cas
            CouchbaseOrm.logger.debug "Data - Delete #{self.id}"
            self.class.collection.remove(self.id, **options)

            self.id = nil
            clear_changes_information
            @destroyed = true
            self.freeze
            self
        end

        alias :remove :delete

        # Deletes the record in the database and freezes this instance to reflect
        # that no changes should be made (since they can't be persisted).
        #
        # There's a series of callbacks associated with #destroy.
        def destroy(with_cas: false, **options)
            return self if destroyed?
            raise 'model not persisted' unless persisted?

            run_callbacks :destroy do
                destroy_associations!

                options[:cas] = @__metadata__.cas if with_cas
                CouchbaseOrm.logger.debug "Data - Destroy #{id}"
                self.class.collection.remove(id, **options)

                self.id = nil

                clear_changes_information
                @destroyed = true
                freeze
            end
        end
        alias_method :destroy!, :destroy

        # Updates a single attribute and saves the record.
        # This is especially useful for boolean flags on existing records. Also note that
        #
        # * Validation is skipped.
        # * \Callbacks are invoked.
        def update_attribute(name, value)
            public_send(:"#{name}=", value)
            changed? ? save(validate: false) : true
        end

        def assign_attributes(hash)
            hash = hash.with_indifferent_access if hash.is_a?(Hash)
            super(hash.except("type"))
        end

        # Updates the attributes of the model from the passed-in hash and saves the
        # record. If the object is invalid, the saving will fail and false will be returned.
        def update(hash)
            assign_attributes(hash)
            save
        end
        alias_method :update_attributes, :update

        # Updates its receiver just like #update but calls #save! instead
        # of +save+, so an exception is raised if the record is invalid and saving will fail.
        def update!(hash)
            assign_attributes(hash) # Assign attributes is provided by ActiveModel::AttributeAssignment
            save!
        end
        alias_method :update_attributes!, :update!

        # Updates the record without validating or running callbacks.
        # Updates only the attributes that are passed in as parameters
        # except if there is more than 16 attributes, in which case
        # the whole record is saved.
        def update_columns(with_cas: false, **hash)
            raise "unable to update columns, model not persisted" unless id

            assign_attributes(hash)

            options = {extended: true}
            options[:cas] = @__metadata__.cas if with_cas

            # There is a limit of 16 subdoc operations per request
            resp = if hash.length <= 16
                self.class.collection.mutate_in(
                    id,
                    hash.map { |k, v| Couchbase::MutateInSpec.replace(k.to_s, v) }
                )
            else
                # Fallback to writing the whole document
                CouchbaseOrm.logger.debug { "Data - Replace #{id} #{attributes.to_s.truncate(200)}" }
                self.class.collection.replace(id, attributes.except("id").merge(type: self.class.design_document), **options)
            end

            # Ensure the model is up to date
            @__metadata__.cas = resp.cas

            changes_applied
            self
        end

        # Reloads the record from the database.
        #
        # This method finds record by its key and modifies the receiver in-place:
        def reload
            raise "unable to reload, model not persisted" unless id

            CouchbaseOrm.logger.debug "Data - Get #{id}"
            resp = self.class.collection.get!(id)
            assign_attributes(decode_encrypted_attributes(resp.content.except("id", *self.class.ignored_properties ))) # API return a nil id
            @__metadata__.cas = resp.cas

            reset_associations
            clear_changes_information
            self
        end

        # Updates the TTL of the document
        def touch(**options)
            CouchbaseOrm.logger.debug "Data - Touch #{id}"
            _res = self.class.collection.touch(id, async: false, **options)
            @__metadata__.cas = resp.cas
            self
        end



        def _update_record(*_args, with_cas: false, **options)
            return false unless perform_validations(:update, options)
            return true unless changed? || self.class.attribute_types.any? { |_, type| type.is_a?(CouchbaseOrm::Types::Nested) || type.is_a?(CouchbaseOrm::Types::Array)  }

            run_callbacks :update do
                run_callbacks :save do
                    options[:cas] = @__metadata__.cas if with_cas
                    CouchbaseOrm.logger.debug { "_update_record - replace #{id} #{serialized_attributes.to_s.truncate(200)}" }
                    if options[:transcoder].nil?
                        options[:transcoder] = CouchbaseOrm::JsonTranscoder.new
                    end
                    resp = self.class.collection.replace(id, serialized_attributes.except("id").merge(type: self.class.design_document), Couchbase::Options::Replace.new(**options))

                    # Ensure the model is up to date
                    @__metadata__.cas = resp.cas

                    changes_applied
                    true
                end
            end
        end
        def _create_record(*_args, **options)
            return false unless perform_validations(:create, options)

            run_callbacks :create do
                run_callbacks :save do
                    assign_attributes(id: self.class.uuid_generator.next(self)) unless self.id
                    CouchbaseOrm.logger.debug { "_create_record - Upsert #{id} #{serialized_attributes.to_s.truncate(200)}" }
                    if options[:transcoder].nil?
                        options[:transcoder] = CouchbaseOrm::JsonTranscoder.new
                    end
                    resp = self.class.collection.upsert(self.id, serialized_attributes.except("id").merge(type: self.class.design_document), Couchbase::Options::Upsert.new(**options))

                    # Ensure the model is up to date
                    @__metadata__.cas = resp.cas

                    changes_applied
                    true
                end
            end
        end

        def perform_validations(context, options = {})
            return valid?(context) if options[:validate] != false
            true
        end
    end
end
