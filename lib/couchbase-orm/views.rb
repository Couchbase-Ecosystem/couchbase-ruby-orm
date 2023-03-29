# frozen_string_literal: true, encoding: ASCII-8BIT

require 'active_model'

module CouchbaseOrm
    module Views
        extend ActiveSupport::Concern


        module ClassMethods
            # Defines a view for the model
            #
            # @param [Symbol, String, Array] names names of the views
            # @param [Hash] options options passed to the {Couchbase::View}
            #
            # @example Define some views for a model
            #  class Post < CouchbaseOrm::Base
            #    view :all
            #    view :by_rating, emit_key: :rating
            #  end
            #
            #  Post.by_rating do |response|
            #    # ...
            #  end
            def view(name, map: nil, emit_key: nil, reduce: nil, **options)
                raise ArgumentError, "#{self} already respond_to? #{name}" if self.respond_to?(name)
                
                if emit_key.class == Array
                    emit_key.each do |key|
                        raise "unknown emit_key attribute for view :#{name}, emit_key: :#{key}" if key && !attribute_names.include?(key.to_s)
                    end
                else
                    raise "unknown emit_key attribute for view :#{name}, emit_key: :#{emit_key}" if emit_key && !attribute_names.include?(emit_key.to_s)
                end

                options = ViewDefaults.merge(options)

                method_opts = {}
                method_opts[:map]    = map    if map
                method_opts[:reduce] = reduce if reduce

                unless method_opts.has_key? :map
                    if emit_key.class == Array
                        method_opts[:map] = <<-EMAP
function(doc) {
    if (doc.type === "{{design_document}}") {
        emit([#{emit_key.map{|key| "doc."+key.to_s}.join(',')}], null);
    }
}
EMAP
                    else
                        emit_key = emit_key || :created_at
                        method_opts[:map] = <<-EMAP
function(doc) {
    if (doc.type === "{{design_document}}") {
        emit(doc.#{emit_key}, null);
    }
}
EMAP
                    end
                end

                @views ||= {}

                name = name.to_sym
                @views[name] = method_opts

                singleton_class.__send__(:define_method, name) do |**opts, &result_modifier|
                    opts = options.merge(opts).reverse_merge(scan_consistency: CouchbaseOrm::N1ql.config[:scan_consistency])
                    CouchbaseOrm.logger.debug("View [#{@design_document}, #{name.inspect}] options: #{opts.inspect}")
                    if result_modifier
                        include_docs(bucket.view_query(@design_document, name.to_s, Couchbase::Options::View.new(**opts.except(:include_docs)))).map(&result_modifier)
                    elsif opts[:include_docs]
                        include_docs(bucket.view_query(@design_document, name.to_s, Couchbase::Options::View.new(**opts.except(:include_docs))))
                    else
                        bucket.view_query(@design_document, name.to_s, Couchbase::Options::View.new(**opts.except(:include_docs)))
                    end
                end
            end
            ViewDefaults = {include_docs: true}

            # add a view and lookup method to the model for finding all records
            # using a value in the supplied attr.
            def index_view(attr, validate: true, find_method: nil, view_method: nil)
                view_method ||= "by_#{attr}"
                find_method ||= "find_#{view_method}"

                validates(attr, presence: true) if validate
                view view_method, emit_key: attr

                instance_eval "
                    def self.#{find_method}(#{attr})
                        #{view_method}(key: #{attr})
                    end
                "
            end

            def ensure_design_document!
                return false unless @views && !@views.empty?
                existing = {}
                update_required = false

                # Grab the existing view details
                begin
                    ddoc = bucket.view_indexes.get_design_document(@design_document, :production)
                rescue Couchbase::Error::DesignDocumentNotFound
                end
                existing = ddoc.views if ddoc
                views_actual = {}
                # Fill in the design documents
                @views.each do |name, document|
                    views_actual[name.to_s] = Couchbase::Management::View.new(
                        document[:map]&.gsub('{{design_document}}', @design_document),
                        document[:reduce]&.gsub('{{design_document}}', @design_document)
                    )
                end

                # Check there are no changes we need to apply
                views_actual.each do |name, desired|
                    check = existing[name]
                    if check
                        cmap = (check.map || '').gsub(/\s+/, '')
                        creduce = (check.reduce || '').gsub(/\s+/, '')
                        dmap = (desired.map || '').gsub(/\s+/, '')
                        dreduce = (desired.reduce || '').gsub(/\s+/, '')

                        unless cmap == dmap && creduce == dreduce
                            update_required = true
                            break
                        end
                    else
                        update_required = true
                        break
                    end
                end

                # Updated the design document
                if update_required
                    document = Couchbase::Management::DesignDocument.new
                    document.views = views_actual
                    document.name = @design_document
                    bucket.view_indexes.upsert_design_document(document, :production)

                    true
                else
                    false
                end
            end

            def include_docs(view_result)
                if view_result.rows.length > 1
                    self.find(view_result.rows.map(&:id))
                elsif view_result.rows.length == 1
                    [self.find(view_result.rows.first.id)]
                else
                    []
                end
            end
        end
    end
end
