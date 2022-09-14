module CouchbaseOrm
    module HasMany
        # :foreign_key, :class_name, :through
        def has_many(model, class_name: nil, foreign_key: nil, through: nil, through_class: nil, through_key: nil, type: :view, **options)
            class_name = (class_name || model.to_s.singularize.camelcase).to_s
            foreign_key = (foreign_key || ActiveSupport::Inflector.foreign_key(self.name)).to_sym
        if through || through_class
            remote_class = class_name
            class_name = (through_class || through.to_s.camelcase).to_s
            through_key = (through_key || "#{remote_class.underscore}_id").to_sym
            remote_method = :"by_#{foreign_key}_with_#{through_key}"
        else
            remote_method = :"find_by_#{foreign_key}"
        end

        instance_var = "@__assoc_#{model}"

        klass = begin
                    class_name.constantize
                rescue NameError
                    warn "WARNING: #{class_name} referenced in #{self.name} before it was aded"

                    # Open the class early - load order will have to be changed to prevent this.
                    # Warning notice required as a misspelling will not raise an error
                    Object.class_eval <<-EKLASS
                        class #{class_name} < CouchbaseOrm::Base
                            attribute :#{foreign_key}
                        end
                    EKLASS
                    class_name.constantize
                end

        build_index(type, klass, remote_class, remote_method, through_key, foreign_key)

        if remote_class
            define_method(model) do
                return self.instance_variable_get(instance_var) if instance_variable_defined?(instance_var)

                remote_klass = remote_class.constantize
                raise ArgumentError, "Can't find #{remote_method} without an id" unless self.id.present?
                enum = klass.__send__(remote_method, key: self.id) { |row|
                    case type
                    when :n1ql
                        remote_klass.find(row)
                    when :view
                        remote_klass.find(row[through_key])
                    else
                        raise 'type is unknown'
                    end
                }

                self.instance_variable_set(instance_var, enum)
            end
        else
            define_method(model) do
                return self.instance_variable_get(instance_var) if instance_variable_defined?(instance_var)
                self.instance_variable_set(instance_var, klass.__send__(remote_method, self.id))
            end
        end

        @associations ||= []
        @associations << [model, options[:dependent]]
        end

        def build_index(type, klass, remote_class, remote_method, through_key, foreign_key)
            case type
            when :n1ql
                build_index_n1ql(klass, remote_class, remote_method, through_key, foreign_key)
            when :view
                build_index_view(klass, remote_class, remote_method, through_key, foreign_key)
            else
                raise 'type is unknown'
            end
        end

        def build_index_view(klass, remote_class, remote_method, through_key, foreign_key)
            if remote_class
                klass.class_eval do
                    view remote_method, map: <<-EMAP
                        function(doc) {
                            if (doc.type === "{{design_document}}" && doc.#{through_key}) {
                            emit(doc.#{foreign_key}, null);
                            }
                        }
                    EMAP
                end
            else
                klass.class_eval do
                    index_view foreign_key, validate: false
                end
            end
        end

        def build_index_n1ql(klass, remote_class, remote_method, through_key, foreign_key)
            if remote_class
                klass.class_eval do
                  n1ql remote_method, emit_key: 'id', query_fn: proc { |bucket, values, options|
                    raise ArgumentError, "values[0] must not be blank" if values[0].blank?
                    cluster.query("SELECT raw #{through_key} FROM `#{bucket.name}` where type = \"#{design_document}\" and #{foreign_key} = #{values[0]}", options)
                  }
                end
            else
                klass.class_eval do
                    index_n1ql foreign_key, validate: false
                end
            end
        end
    end
end
