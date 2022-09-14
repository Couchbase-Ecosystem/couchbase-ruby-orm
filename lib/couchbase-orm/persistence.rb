# frozen_string_literal: true, encoding: ASCII-8BIT

require 'active_model'
require 'active_support/hash_with_indifferent_access'

module CouchbaseOrm
    module Persistence
        extend ActiveSupport::Concern

        include Encrypt

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
            @__metadata__.cas.nil? && @__metadata__.key.nil?
        end
        alias_method :new?, :new_record?

        # Returns true if this object has been destroyed, otherwise returns false.
        def destroyed?
            !!(@__metadata__.cas && @__metadata__.key.nil?)
        end

        # Returns true if the record is persisted, i.e. it's not a new record and it was
        # not destroyed, otherwise returns false.
        def persisted?
            # Changed? is provided by ActiveModel::Dirty
            !!@__metadata__.key
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
            CouchbaseOrm.logger.debug "Data - Delete #{@__metadata__.key}"
            self.class.collection.remove(@__metadata__.key, **options)

            @__metadata__.key = nil
            @id = nil

            clear_changes_information
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
                CouchbaseOrm.logger.debug "Data - Delete #{@__metadata__.key}"
                self.class.collection.remove(@__metadata__.key, **options)

                @__metadata__.key = nil
                @id = nil

                clear_changes_information
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
            _id = @__metadata__.key
            raise "unable to update columns, model not persisted" unless _id

            assign_attributes(hash)

            options = {extended: true}
            options[:cas] = @__metadata__.cas if with_cas

            # There is a limit of 16 subdoc operations per request
            resp = if hash.length <= 16
                self.class.collection.mutate_in(
                    _id,
                    hash.map { |k, v| Couchbase::MutateInSpec.replace(k.to_s, v) }
                )
            else
                # Fallback to writing the whole document
                @__attributes__[:type] = self.class.design_document
                @__attributes__.delete(:id)
                CouchbaseOrm.logger.debug { "Data - Replace #{_id} #{@__attributes__.to_s.truncate(200)}" }
                self.class.collection.replace(_id, @__attributes__, **options)
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
            key = @__metadata__.key
            raise "unable to reload, model not persisted" unless key

            CouchbaseOrm.logger.debug "Data - Get #{key}"
            resp = self.class.collection.get!(key)
            @__attributes__ = ::ActiveSupport::HashWithIndifferentAccess.new(resp.content)
            @__metadata__.key = key
            @__metadata__.cas = resp.cas

            decrypted_attributes(@__attributes__)

            reset_associations
            clear_changes_information
            self
        end

        # Updates the TTL of the document
        def touch(**options)
            CouchbaseOrm.logger.debug "Data - Touch #{@__metadata__.key}"
            res = self.class.collection.touch(@__metadata__.key, async: false, **options)
            @__metadata__.cas = resp.cas
            self
        end


        protected


        def _update_record(with_cas: false, **options)
            return false unless perform_validations(:update, options)
            return true unless changed?

            run_callbacks :update do
                run_callbacks :save do
                    # Ensure the type is set
                    @__attributes__[:type] = self.class.design_document
                    @__attributes__.delete(:id)

                    encrypted_attributes(@__attributes__)

                    _id = @__metadata__.key
                    options[:cas] = @__metadata__.cas if with_cas
                    CouchbaseOrm.logger.debug { "_update_record - replace #{_id} #{@__attributes__.to_s.truncate(200)}" }
                    resp = self.class.collection.replace(_id, @__attributes__, Couchbase::Options::Replace.new(**options))

                    # Ensure the model is up to date
                    @__metadata__.key = _id
                    @__metadata__.cas = resp.cas

                    changes_applied
                    true
                end
            end
        end
        def _create_record(**options)
            return false unless perform_validations(:create, options)

            run_callbacks :create do
                run_callbacks :save do
                    # Ensure the type is set
                    @__attributes__[:type] = self.class.design_document
                    @__attributes__.delete(:id)

                    encrypted_attributes(@__attributes__)

                    _id = @id || self.class.uuid_generator.next(self)
                    CouchbaseOrm.logger.debug { "_create_record - Upsert #{_id} #{@__attributes__.to_s.truncate(200)}" }
                    #resp = self.class.collection.add(_id, @__attributes__, **options)

                    resp = self.class.collection.upsert(_id, @__attributes__, Couchbase::Options::Upsert.new(**options))

                    # Ensure the model is up to date
                    @__metadata__.key = _id
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
