require "couchbase-orm/types/date"
require "couchbase-orm/types/date_time"
require "couchbase-orm/types/timestamp"

if ActiveModel::VERSION::MAJOR < 6
  # In Rails 5, the type system cannot allow overriding the default types
  ActiveModel::Type.registry.instance_variable_get(:@registrations).delete_if do |k|
    k.matches?(:date) || k.matches?(:datetime) || k.matches?(:timestamp)
  end
end

ActiveModel::Type.register(:date, CouchbaseOrm::Types::Date)
ActiveModel::Type.register(:datetime, CouchbaseOrm::Types::DateTime)
ActiveModel::Type.register(:timestamp, CouchbaseOrm::Types::Timestamp)
