# frozen_string_literal: true, encoding: ASCII-8BIT

module CouchbaseOrm
    autoload :Encrypt,      'couchbase-orm/encrypt'
    autoload :Error,       'couchbase-orm/error'
    autoload :Connection,  'couchbase-orm/connection'
    autoload :IdGenerator, 'couchbase-orm/id_generator'
    autoload :Base,        'couchbase-orm/base'
    autoload :HasMany,     'couchbase-orm/utilities/has_many'

    def self.logger
        @@logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def self.logger=(logger)
        @@logger = logger
    end

    def self.try_load(id)
        result = nil
        was_array = id.is_a?(Array)
        if was_array && id.length == 1
            query_id = id.first
        else
            query_id = id
        end

        result = query_id.is_a?(Array) ? CouchbaseOrm::Base.bucket.default_collection.get_multi(query_id) : CouchbaseOrm::Base.bucket.default_collection.get(query_id)

        result = Array.wrap(result) if was_array

        if result&.is_a?(Array)
            return result.zip(id).map { |r, id| try_load_create_model(r, id) }.compact
        end

        return try_load_create_model(result, id)
    end

    private

    def self.try_load_create_model(result, id)
        ddoc = result&.content["type"]
        return nil unless ddoc
        ::CouchbaseOrm::Base.descendants.each do |model|
            if model.design_document == ddoc
                return model.new(result, id: id)
            end
        end
        nil
    end
end

# Provide Boolean conversion function
# See: http://www.virtuouscode.com/2012/05/07/a-ruby-conversion-idiom/
module Kernel
    private

    def Boolean(value)
        case value
        when String, Symbol
            case value.to_s.strip.downcase
            when 'true'
                return true
            when 'false'
                return false
            end
        when Integer
            return value != 0
        when false, nil
            return false
        when true
            return true
        end

        raise ArgumentError, "invalid value for Boolean(): \"#{value.inspect}\""
    end
end
class Boolean < TrueClass; end

# If we are using Rails then we will include the Couchbase railtie.
if defined?(Rails)
    require 'couchbase-orm/railtie'
end

