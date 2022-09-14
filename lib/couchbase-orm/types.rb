require "couchbase-orm/types/date"
require "couchbase-orm/types/date_time"
require "couchbase-orm/types/timestamp"

ActiveModel::Type.register(:date, CouchbaseOrm::Types::Date)
ActiveModel::Type.register(:datetime, CouchbaseOrm::Types::DateTime)
ActiveModel::Type.register(:timestamp, CouchbaseOrm::Types::Timestamp)
