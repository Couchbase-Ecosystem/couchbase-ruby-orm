require 'set'
require 'active_support/concern'

module CouchbaseOrm
    # Controls what happens when a document (or a Hash/Parameters passed to
    # `new`/`assign_attributes`) carries a key that has no corresponding
    # attribute or writer on the model.
    #
    # By default (`raise_on_unknown_attributes = true`) this is unchanged
    # ActiveModel behaviour: an `ActiveModel::UnknownAttributeError` is
    # raised. Setting it to `false` on a model (it is inherited, like any
    # `class_attribute`) makes unknown keys tolerated instead: they are
    # dropped before assignment and a warning is logged.
    #
    # This exists to survive rolling/canary deploys: a document written by a
    # pod running newer code can carry attributes a pod still running older
    # code does not know about yet. Without this, reading that document on
    # the old code raises and the request fails.
    #
    # A key is considered "known" using the same test ActiveModel itself uses
    # to decide whether to raise (`respond_to?(:"#{key}=")`), not attribute
    # membership - this matters because association writers (`belongs_to`,
    # `has_and_belongs_to_many`) define a setter (e.g. `parent=`) for a name
    # that is not itself a declared attribute (the attribute is `parent_id`).
    # Filtering by attribute name would silently drop those.
    #
    # Unknown keys are only ever dropped from the in-memory assignment. If
    # the model is saved afterwards, `serialized_attributes` only emits
    # declared attributes, so the unknown key disappears from the stored
    # document too - the same trade-off `ignored_properties` already makes.
    module UnknownAttributes
        extend ActiveSupport::Concern

        # Caps the process-wide memory used to track which (class, key)
        # warnings have already been emitted. Unknown keys come from
        # document content, i.e. are not under the application's control,
        # so this must be bounded. Once the cap is hit, unknown attributes
        # are still filtered (and still logged at debug level) - only the
        # warn-once escalation stops.
        MAX_WARNED = 1_000

        @warned = Set.new

        included do
            class_attribute :raise_on_unknown_attributes,
                             instance_accessor: false, instance_predicate: false, default: true
        end

        # Filters out unknown keys before assignment when
        # `raise_on_unknown_attributes` is false; otherwise unchanged.
        def assign_attributes(attributes)
            return super if self.class.raise_on_unknown_attributes
            # Garbage input (nil, an Integer, a bare Object...) must still get
            # ActiveModel's own "you must pass a hash" ArgumentError from
            # `super`, not a NoMethodError from calling each_pair on it below.
            return super unless attributes.respond_to?(:each_pair)

            unknown = attributes.each_pair.filter_map { |key, _| key unless respond_to?(:"#{key}=") }
            return super if unknown.empty?

            UnknownAttributes.report(self.class, unknown)
            super(attributes.except(*unknown))
        end
        alias_method :attributes=, :assign_attributes

        class << self
            # @api private
            def report(klass, keys)
                CouchbaseOrm.logger.debug { "#{klass.name}: ignoring unknown properties #{keys.inspect}" }

                newly_warned = @warned.size >= MAX_WARNED ? [] : keys.select { |key| @warned.add?("#{klass.name}##{key}") }
                return if newly_warned.empty?

                CouchbaseOrm.logger.warn(
                    "#{klass.name}: ignoring unknown document properties #{newly_warned.join(', ')} " \
                    "(raise_on_unknown_attributes is false for this class - " \
                    "they will not be persisted if the document is saved)"
                )
            end
        end
    end
end
