module CouchbaseOrm
    module Enum
        private

        def enum(options)
            # options contains an optional default value, and the name of the
            # enum, e.g enum visibility: %i(group org public), default: :group
            default = options.delete(:default)
            name = options.keys.first.to_sym
            values = options[name]

            # values is assumed to be a list of symbols. each value is assigned an
            # integer, and this number is used for db storage. numbers start at 1.
            mapping = {}
            values.each_with_index do |value, i|
                mapping[value.to_sym] = i + 1
                mapping[i + 1] = value.to_sym
            end

            # VISIBILITY = {group: 0, 0: group ...}
            const_set(name.to_s.upcase, mapping)

            # lookup the default's integer value
            if default
                default_value = mapping[default]
                raise 'Unknown default value' unless default_value
            else
                default_value = 1
            end
            attribute name, :integer, default: default_value

            define_method "#{name}=" do |value|
                unless value.nil?
                    value = case value
                    when Symbol, String
                        self.class.const_get(name.to_s.upcase)[value.to_sym]
                    else
                        Integer(value)
                    end
                end
                super(value)
            end

            # keep the attribute's value within bounds
            before_save do |record|
                value = record[name]

                unless value.nil?
                    value = case value
                    when Symbol, String
                        record.class.const_get(name.to_s.upcase)[value.to_sym]
                    else
                        Integer(value)
                    end
                end

                record[name] = (1..values.length).cover?(value) ? value : default_value
            end
        end
    end
end
