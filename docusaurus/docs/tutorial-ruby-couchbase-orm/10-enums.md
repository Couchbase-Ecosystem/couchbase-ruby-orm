# Enums

CouchbaseOrm provides support for enums, which allow you to define a fixed set of values for an attribute. Enums are useful when you have a limited number of possible values for a particular attribute and want to ensure data consistency and validity.

## 10.1. Defining Enums

To define an enum in your model, you can use the `enum` class method provided by CouchbaseOrm.

```ruby
class User < CouchbaseOrm::Base
  enum status: [:active, :inactive, :suspended]
end
```

In this example, we define an enum named `status` for the `User` model. The enum has three possible values: `:active`, `:inactive`, and `:suspended`.

## 10.2. Using Enums

You can assign enum values to an attribute using the generated methods or by directly assigning the value.

```ruby
user = User.new
user.status = :active
user.save

user.suspended!
user.save

puts user.status  # Output: "suspended"
```

In this example, we create a new `User` instance and set the `status` to `:active` using the direct assignment. We then change the `status` to `:suspended` using the generated `suspended!` method.

## 10.3. Querying by Enums

CouchbaseOrm allows you to query records based on their enum values.

```ruby
active_users = User.where(status: 1)
suspended_users = User.where(status: 3)
```

These queries retrieve users with the `status` enum set to `:active` and `:suspended`, respectively.

## 10.4. Enum Mapping

Behind the scenes, CouchbaseOrm maps the enum values to integers for storage in the database. By default, the mapping starts from 0 and increments by 1 for each enum value in the order they are defined.

However, you can customize the mapping by providing a hash of enum values and their corresponding integer values.

```ruby
class User < CouchbaseOrm::Base
  enum status: { active: 1, inactive: 2, suspended: 3 }
end
```

In this example, we explicitly define the mapping of enum values to integers. The `:active` value is mapped to 1, `:inactive` to 2, and `:suspended` to 3.

## 10.5. Enum Validation

CouchbaseOrm automatically validates that the assigned enum value is one of the defined values for the enum.

```ruby
user = User.new
user.status = :invalid
user.save # Raises an error: "Invalid enum value: :invalid"
```

If you try to assign an invalid value to an enum attribute, CouchbaseOrm will raise an error indicating that the value is not a valid enum value.

## 10.6. Enum Defaults

You can specify a default value for an enum attribute using the `default` option.

```ruby
class User < CouchbaseOrm::Base
  enum status: [:active, :inactive, :suspended], default: :active
end
```

In this example, if no value is assigned to the `status` attribute when creating a new `User` instance, the default value of `:active` will be used.

Enums in CouchbaseOrm provide a convenient way to define a fixed set of values for an attribute. They help ensure data consistency, improve code readability, and simplify querying and validation.

When using enums, consider the following:

- Enums are stored as integers in the database, so be cautious when changing the order or removing enum values, as it may affect existing records.
- Enums are case-sensitive, so `:active` and `:Active` are considered different values.
- Enums can be used in combination with other attribute types, such as `default` and `validates`, to further customize the behavior of the attribute.

In the next section, we'll explore how to use encryption in CouchbaseOrm to secure sensitive data stored in your Couchbase documents.
