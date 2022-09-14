module CouchbaseOrm
    module Index
        private

        def index(attrs, name = nil, presence: true, &processor)
            attrs = Array(attrs).flatten
            name ||= attrs.map(&:to_s).join('_')

            find_by_method          = "find_by_#{name}"
            processor_method        = "process_#{name}"
            bucket_key_method       = "#{name}_bucket_key"
            bucket_key_vals_method  = "#{name}_bucket_key_vals"
            class_bucket_key_method = "generate_#{bucket_key_method}"
            original_bucket_key_var = "@original_#{bucket_key_method}"


            #----------------
            # keys
            #----------------
            # class method to generate a bucket key given input values
            define_singleton_method(class_bucket_key_method) do |*values|
                processed = self.send(processor_method, *values)
                "#{@design_document}#{name}-#{processed}"
            end

            # instance method that uses the class method to generate a bucket key
            # given the current value of each of the key's component attributes
            define_method(bucket_key_method) do |args = nil|
                self.class.send(class_bucket_key_method, *self.send(bucket_key_vals_method))
            end

            # collect a list of values for each key component attribute
            define_method(bucket_key_vals_method) do
                attrs.collect {|attr| self[attr]}
            end


            #----------------
            # helpers
            #----------------
            # simple wrapper around the processor proc if supplied
            define_singleton_method(processor_method) do |*values|
                if processor
                    processor.call(values.length == 1 ? values.first : values)
                else
                    values.join('-')
                end
            end

            # use the bucket key as an index - lookup records by attr values
            define_singleton_method(find_by_method) do |*values|
                key = self.send(class_bucket_key_method, *values)
                CouchbaseOrm.logger.debug("#{find_by_method}: #{class_bucket_key_method} with values #{values.inspect} give key: #{key}")
                id = self.collection.get(key)&.content
                if id
                    mod = self.find_by_id(id)
                    return mod if mod

                    # Clean up record if the id doesn't exist
                    self.collection.remove(key)
                else
                    CouchbaseOrm.logger.debug("#{find_by_method}: #{key} not found")
                end

                nil
            end


            #----------------
            # validations
            #----------------
            # ensure each component of the unique key is present
            if presence
                attrs.each do |attr|
                    validates attr, presence: true
                    attribute attr
                end
            end

            define_method("#{name}_unique?") do
                values = self.send(bucket_key_vals_method)
                other  = self.class.send(find_by_method, *values)
                !other || other.id == self.id
            end


            #----------------
            # callbacks
            #----------------
            # before a save is complete, while changes are still available, store
            # a copy of the current bucket key for comparison if any of the key
            # components have been modified
            before_save do |record|
                if attrs.any? { |attr| record.changes.include?(attr) }
                    args = attrs.collect { |attr| send(:"#{attr}_was") || send(attr) }
                    instance_variable_set(original_bucket_key_var, self.class.send(class_bucket_key_method, *args))
                end
            end

            # after the values are persisted, delete the previous key and store the
            # new one. the id of the current record is used as the key's value.
            after_save do |record|
                original_key = instance_variable_get(original_bucket_key_var)

                if original_key
                    begin
                        check_ref_id = record.class.collection.get(original_key)
                        if check_ref_id && check_ref_id.content == record.id
                            CouchbaseOrm.logger.debug "Removing old key #{original_key}"
                            record.class.collection.remove(original_key, cas: check_ref_id.cas)
                        end
                    end
                end

                unless presence == false && attrs.length == 1 && record[attrs[0]].nil?
                    record.class.collection.upsert(record.send(bucket_key_method), record.id)
                end
                instance_variable_set(original_bucket_key_var, nil)
            end

            # cleanup by removing the bucket key before the record is deleted
            # TODO: handle unpersisted, modified component values
            before_destroy do |record|
                check_ref_id = record.class.collection.get(record.send(bucket_key_method))
                if check_ref_id && check_ref_id.content == record.id
                    record.class.collection.remove(record.send(bucket_key_method), cas: check_ref_id.cas)
                end
                true
            end

            # return the name used to construct the added method names so other
            # code can call the special index methods easily
            return name
        end

    end
end
