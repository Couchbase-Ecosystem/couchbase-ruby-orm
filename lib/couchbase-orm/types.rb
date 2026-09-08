require "couchbase-orm/types/date"
require "couchbase-orm/types/date_time"
require "couchbase-orm/types/timestamp"
require "couchbase-orm/types/array"
require "couchbase-orm/types/nested"
require "couchbase-orm/types/encrypted"

ActiveModel::Type.register(:date, CouchbaseOrm::Types::Date)
ActiveModel::Type.register(:datetime, CouchbaseOrm::Types::DateTime)
ActiveModel::Type.register(:timestamp, CouchbaseOrm::Types::Timestamp)
ActiveModel::Type.register(:array, CouchbaseOrm::Types::Array)
ActiveModel::Type.register(:nested, CouchbaseOrm::Types::Nested)
ActiveModel::Type.register(:encrypted, CouchbaseOrm::Types::Encrypted)
