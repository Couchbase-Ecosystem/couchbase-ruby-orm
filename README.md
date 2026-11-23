# Couchbase ORM for Rails

## Documentation
https://www.couchbase-ruby-orm.com

## Installation
Add this line to your application's Gemfile:
```ruby
gem 'couchbase-orm', git: 'https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm' 
```
And then execute:

    $ bundle install

## Rails integration

Create a couchbase-orm config file `config/couchbase.yml`

```yaml
    common: &common
      connection_string: couchbase://localhost
      username: dev_user
      password: dev_password

    development:
      <<: *common
      bucket: dev_bucket

    test:
      <<: *common
      bucket: dev_bucket_test

    # set these environment variables on your production server
    production:
      connection_string: <%= ENV['COUCHBASE_CONNECTION_STRING'] %>
      bucket: <%= ENV['COUCHBASE_BUCKET'] %>
      username: <%= ENV['COUCHBASE_USER'] %>
      password: <%= ENV['COUCHBASE_PASSWORD'] %>
```

## Setup without Rails

If you are not using Rails, you can configure couchbase-orm with an initializer:

```ruby
# config/initializers/couchbase_orm.rb
CouchbaseOrm::Connection.config = {
  connection_string: "couchbase://localhost"
  username: "dev_user"
  password: "dev_password"
  bucket: "dev_bucket"
}
```

## Examples

```ruby
    require 'couchbase-orm'

    class Post < CouchbaseOrm::Base
      attribute :title, :string
      attribute :body,  :string
      attribute :draft, :boolean
    end

    p = Post.new(id: 'hello-world',
                 title: 'Hello world',
                 draft: true)
    p.save
    p = Post.find('hello-world')
    p.body = "Once upon the times...."
    p.save
    p.update(draft: false)
    Post.bucket.get('hello-world')  #=> {"title"=>"Hello world", "draft"=>false,
                                    #    "body"=>"Once upon the times...."}
```

You can also let the library generate the unique identifier for you:

```ruby
    p = Post.create(title: 'How to generate ID',
                    body: 'Open up the editor...')
    p.id        #=> "post-abcDE34"
```

<!-- You can define connection options on per model basis:

```ruby
    class Post < CouchbaseOrm::Base
      attribute :title, :string
      attribute :body,  :string
      attribute :draft, :boolean

      connect bucket: 'blog', password: ENV['BLOG_BUCKET_PASSWORD']
    end
``` -->

## Typing

The following types have been tested :

- :string
- :integer
- :float
- :boolean
- :date
- :datetime (stored as iso8601, use precision: n to store more decimal precision)
- :timestamp (stored as integer)
- :encrypted
  - Provides storage format compatible with Couchbase Lite field-level encryption
  - See <https://docs.couchbase.com/couchbase-lite/current/c/field-level-encryption.html>
  - **Important**: CouchbaseOrm does not perform encryption/decryption - your application must encrypt data before storing it
  - Values must be Base64-encoded strings containing pre-encrypted ciphertext
  - See the [encryption documentation](https://www.couchbase-ruby-orm.com/docs/tutorial-ruby-couchbase-orm/encryption) for details
- :array (see below)
- :nested (see below)

You can register other types in ActiveModel registry :

```ruby
    class DateTimeWith3Decimal < CouchbaseOrm::Types::DateTime
      def serialize(value)
        value&.iso8601(3)
      end
    end

    ActiveModel::Type.register(:datetime3decimal, DateTimeWith3Decimal)
```

## Validations

There are all methods from ActiveModel::Validations accessible in
context of rails application. You can also enforce types using ruby
[conversion methods](http://www.virtuouscode.com/2012/05/07/a-ruby-conversion-idiom/)

```ruby
    class Comment < Couchbase::Model
      attribute :author, :string
      attribute :body, :string

      validates_presence_of :author, :body
    end
```

## Ignored properties

```ruby
    class Comment < CouchbaseOrm::Base
      self.ignored_properties = [:old_name] # ignore old_name property in the model
      self.properties_always_exists_in_document = true # use is null for nil value instead of not valued for performance purpose, only possible if all properties always exists in document
    end
```      
You can specify `properties_always_exists_in_document` to true if all properties always exists in document, this will allow to use `is null` instead of `not valued` for nil value, this will improve performance. 

## Schema evolution

`ignored_properties` (above) drops a named, fixed list of legacy keys wherever a document is
decoded. For the more general case of a rolling/canary deploy - where a document written by a pod
running newer code can carry an attribute a pod still running older code hasn't declared yet -
there is `raise_on_unknown_attributes`:

```ruby
    class Comment < CouchbaseOrm::Base
      self.raise_on_unknown_attributes = false # tolerate any undeclared document key instead of raising
    end
```

With the default (`true`), an undeclared key anywhere in `new`, `assign_attributes`, `find` or
`reload` raises `ActiveModel::UnknownAttributeError`, same as plain ActiveModel. Set it to `false`
and undeclared keys are dropped instead, with a warning logged the first time each one is seen on
a given class. Unlike `ignored_properties`, it is a `class_attribute`, so it is inherited by
subclasses and can be set once for a whole hierarchy (e.g. on your app's own base class) or
globally via `CouchbaseOrm::Document.raise_on_unknown_attributes = false`.

Because a dropped key was never assigned to an attribute, it is not written back out either: if
the model is saved afterwards, the key disappears from the stored document. If you need to
preserve an unknown key across a load-then-save round trip rather than only tolerate it on load,
`ignored_properties` won't help with that either - both mechanisms are read-side tolerance, not a
schemaless passthrough.

WARNING: If a document exists without a property, the query will failed! So you must be sure that all documents have all properties.


## N1ql

N1QL queries can be defined in the model to filter or order results.

> Couchbase Views (map/reduce, `view` / `index_view` / `ensure_design_document!`) are no longer supported:
> Couchbase Server 8.0 uses the Magma storage backend by default, which does not support Views. Use N1QL instead.

```ruby
    class Comment < CouchbaseOrm::Base
      attribute :author, :string
      attribute :body, :string
      n1ql :by_author, emit_key: :author

      # Generates two functions:
      # * a by_author N1QL query
      # * def find_by_author(author); end
      index_n1ql :author

      # You can make compound keys by passing an array to :emit_key
      # this allow to query by read/unread comments
      n1ql :by_read, emit_key: [:user_id, :read]
      # this allow to query by view_count
      n1ql :by_view_count, emit_key: [:user_id, :view_count]

      validates_presence_of :author, :body
    end
```

## Basic Active Record like query engine

```ruby
class Comment < CouchbaseOrm::Base
      attribute :title, :string
      attribute :author, :string
      attribute :category, :string
      attribute :ratings, :number
end

Comment.where(author: "Anne McCaffrey", category: ['S-F', 'Fantasy']).not(ratings: 0).order(:title).limit(10)

# Relation can be composed as in AR:

amc_comments = Comment.where(author: "Anne McCaffrey")

amc_comments.count

amc_sf_comments = amc_comments.where(category: 'S-F')

# pluck is available, but will query all object fields first

Comment.pluck(:title, :ratings)

# To load the ids without loading the models

Comment.where(author: "David Eddings").ids

# To delete all the models of a relation

Comment.where(ratings: 0).delete_all
```

## scopes

Scopes can be written as class method, scope method is not implemented yet.
They can be chained as in AR or mixed with relation methods.

```ruby
class Comment < CouchbaseOrm::Base
      attribute :title, :string
      attribute :author, :string
      attribute :category, :string
      attribute :ratings, :number

      def self.by_author(author)
        where(author: author)
      end
end

Comment.by_author("Anne McCaffrey").where(category: 'S-F').not(ratings: 0).order(:title).limit(10)
```

## Operators

Several operators are available to filter numerical results : \_gt, \_lt, \_gte, \_lte, \_ne
  
  ```ruby
  Comment.where(ratings: {_gt: 3})
  ```

## Range in the where

You can specify a Range of date or intger in the where clause

  ```ruby
  Person.where(birth_date: DateTime.new(1980, 1, 1)..DateTime.new(1990, 1, 1))
  Person.where(age: 10..20)

  Person.where(age: 10...20) # to exclude the upper bound
  ```

## Associations and Indexes

There are common active record helpers available for use `belongs_to` and `has_many`

```ruby
    class Comment < CouchbaseOrm::Base
        belongs_to :author
    end

    class Author < CouchbaseOrm::Base
        has_many :comments, dependent: :destroy

        # You can ensure an attribute is unique for this model
        attribute :email, :string
        ensure_unique :email
    end
```

`has_many` associations are resolved with N1QL queries:

  ```ruby
  class Comment < CouchbaseOrm::Base
      belongs_to :author
  end

  class Author < CouchbaseOrm::Base
      has_many :comments, dependent: :destroy
  end
  ```

## Nested

Attributes can be of type nested, they must specify a type of NestedDocument.
The NestedValidation triggers nested validation on parent validation.

```ruby
    class Address < CouchbaseOrm::NestedDocument
      attribute :road, :string
      attribute :city, :string
      validates :road, :city, presence: true
    end

    class Author < CouchbaseOrm::Base
        attribute :address, :nested, type: Address
        validates :address, nested: true
    end
```

Model can be queried using the nested attributes

```ruby
    Author.where(address: {road: '1 rue de la paix', city: 'Paris'})
```

## Array

Attributes can be of type array, they must contain something that can be serialized and deserialized to/from JSON.
You can enforce the type of array elements. The type can be a NestedDocument

```ruby
    class Book < CouchbaseOrm::NestedDocument
      attribute :name, :string
      validates :name, presence: true
    end 

    class Author < CouchbaseOrm::Base
        attribute things, :array
        attribute flags, :array, type: :string
        attribute books, :array, type: Book

        validates :books, nested: true
    end
```

## Performance Comparison with Couchbase-Ruby-Model

Basically we migrated an application from [Couchbase Ruby Model](https://github.com/couchbase/couchbase-ruby-model)
to [Couchbase-ORM](https://github.com/acaprojects/couchbase-orm) (this project)

- Rails 5 production
- Puma as the webserver
- Running on a 2015 Macbook Pro
- Performance test: `siege -c250 -r10  http://localhost:3000/auth/authority`

The request above pulls the same database document each time and returns it. A simple O(1) operation.

| Stat | Couchbase Ruby Model | Couchbase-ORM |
| :--- | :---                 |   :---        |
|Transactions|2500 hits|2500 hits|
|Elapsed time|12.24 secs|6.82 secs|
|Response time|0.88 secs|0.34 secs|
|Transaction rate|204.25 trans/sec|366.57 trans/sec|
|Request Code|[ruby-model-app](https://github.com/QuayPay/coauth/blob/95bbf5e5c3b3340e5af2da494b90c91c5e3d6eaa/app/controllers/auth/authorities_controller.rb#L6)|[couch-orm-app](https://github.com/QuayPay/coauth/blob/87f6fdeaab784ba252a5d38bbcf9e6b0477bb504/app/controllers/auth/authorities_controller.rb#L8)|

---

## 📢 Support Policy

We truly appreciate your interest in this project!  
This project is **community-maintained**, which means it's **not officially supported** by our support team.

If you need help, have found a bug, or want to contribute improvements, the best place to do that is right here — by [opening a GitHub issue](https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm/issues).  
Our support portal is unable to assist with requests related to this project, so we kindly ask that all inquiries stay within GitHub.

Your collaboration helps us all move forward together — thank you!
