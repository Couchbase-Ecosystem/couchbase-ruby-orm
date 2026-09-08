# Logging

CouchbaseOrm provides a logging mechanism to help you monitor and debug your application. Logging allows you to capture important events, errors, and information during the execution of your application. CouchbaseOrm integrates with the logging framework used in your Ruby application, such as the built-in `Logger` class or third-party logging libraries.


## 12.1. Log Levels

CouchbaseOrm supports different log levels to control the verbosity of the logged messages. The available log levels, in increasing order of severity, are:

- `DEBUG`: Detailed information, typically of interest only when diagnosing problems.
- `INFO`: Confirmation that things are working as expected.
- `WARN`: An indication that something unexpected happened or indicative of some problem in the near future.
- `ERROR`: Due to a more serious problem, the software has not been able to perform some function.
- `FATAL`: A serious error, indicating that the program itself may be unable to continue running.

By default, CouchbaseOrm logs messages at the `INFO` level and above. You can change the log level by exporting the `COUCHBASE_ORM_DEBUG` environment variable with the desired log level. For example, to set the log level to `DEBUG`, you can run:

```bash
export COUCHBASE_ORM_DEBUG=Logger::DEBUG
```

This command sets the log level to `DEBUG`, which will log detailed information for debugging purposes.

```ruby
require_relative "app"

# Create a new user
user = User.new(name: 'John Doe', email: 'john@example.com')
user.save

# Update the user's email
user.email = 'john.doe@example.com'
user.save

# Log a custom message
CouchbaseOrm.logger.info "User #{user.id} updated email to #{user.email}"
```

In this example, we create a new `User` instance, save it to the database, update the user's email, and log a custom message using the `CouchbaseOrm.logger` object. The log message includes the user's ID and the updated email address.

Output:
```
D, [2024-05-24T11:48:00.071104 #234447] DEBUG -- : Initialize model  with {:name=>"John Doe", :email=>"john@example.com"}
D, [2024-05-24T11:48:00.086972 #234447] DEBUG -- : _create_record - Upsert user-1-vncZNSYZj {"id"=>"user-1-vncZNSYZj", "email"=>"john@example.com", "name"=>"John Doe", "age"=>nil, "height"=>nil, "is_active"=>nil, "birth_date"=>nil, "created_at"=>"2024-05-24T06:18:00Z", "updated_at"=>"2024...
D, [2024-05-24T11:48:00.113166 #234447] DEBUG -- : _update_record - replace user-1-vncZNSYZj {"id"=>"user-1-vncZNSYZj", "email"=>"john.doe@example.com", "name"=>"John Doe", "age"=>nil, "height"=>nil, "is_active"=>nil, "birth_date"=>nil, "created_at"=>"2024-05-24T06:18:00Z", "updated_at"=>"...
I, [2024-05-24T11:48:00.115239 #234447]  INFO -- : User user-1-vncZNSYZj updated email to john.doe@example.com
```

## 12.2. Unknown Attribute Warnings

When a model has [`raise_on_unknown_attributes`](./03-defining-models.md#37-handling-unknown-document-properties)
set to `false`, every `assign_attributes` call (from `new`, `find`, `reload`, ...) that drops an
undeclared key logs at `DEBUG` level. To avoid flooding your logs on high-traffic models, a `WARN`
is only emitted the first time a given (model class, property name) pair is seen in the process:

```
D, [...] DEBUG -- : User: ignoring unknown properties ["legacy_field"]
W, [...]  WARN -- : User: ignoring unknown document properties legacy_field (raise_on_unknown_attributes is false for this class - they will not be persisted if the document is saved)
```

That warning tracking is capped so it cannot grow unbounded.

