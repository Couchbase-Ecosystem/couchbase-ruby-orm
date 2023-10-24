module ActiveRecordCompat
  # try to avoid dependencies on too many active record classes
  # by exemple we don't want to go down to the concept of tables

  extend ActiveSupport::Concern

  module ClassMethods
    def base_class?
      true
    end

    def column_names # can't be an alias for now
      attribute_names
    end

    def abstract_class?
      false
    end

    def connected?
      true
    end

    def table_exists?
      true
    end

    def _reflect_on_association(_attribute)
      false
    end

    def type_for_attribute(attribute)
      attribute_types[attribute]
    end

    if ActiveModel::VERSION::MAJOR < 6
      def attribute_names
        attribute_types.keys
      end
    end
  end

  def slice(*methods)
    methods.flatten.index_with { |method| public_send(method) }.with_indifferent_access
  end

  def values_at(*methods)
    methods.flatten.map! { |method| public_send(method) }
  end

  def _has_attribute?(attr_name)
    attribute_names.include?(attr_name.to_s)
  end

  def attribute_for_inspect(attr_name)
    value = send(attr_name)
    value.inspect
  end

  if ActiveModel::VERSION::MAJOR < 6
    def attribute_names
      self.class.attribute_names
    end

    def has_attribute?(attr_name)
      @attributes.key?(attr_name.to_s)
    end

    def attribute_present?(attribute)
      value = send(attribute)
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end

    def _write_attribute(attr_name, value)
      @attributes.write_from_user(attr_name.to_s, value)
      value
    end
  end
end
