module CouchbaseOrm
  module StrictLoading
    extend ActiveSupport::Concern

    included do
      class_attribute :strict_loading_by_default, instance_accessor: false, default: false
    end

    def init_strict_loading
      @strict_loading = self.class.strict_loading_by_default
    end

    def strict_loading!
      @strict_loading = true
    end

    def strict_loading?
      !!@strict_loading
    end
  end
end