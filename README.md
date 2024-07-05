# Couchbase ORM for Rails

## Documentation
https://couchbase-ruby-orm.com

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

Views are generated on application load if they don't exist or mismatch.
This works fine in production however by default in development models are lazy loaded.

    # config/environments/development.rb
    config.eager_load = true

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
  - see <https://docs.couchbase.com/couchbase-lite/current/c/field-level-encryption.html>
  - You must store a string that can be encoded in json (not binary data), use base64 if needed
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

## Views (aka Map/Reduce indexes)

Views are defined in the model and typically just emit an attribute that
can then be used for filtering results or ordering.

```ruby
    class Comment < CouchbaseOrm::Base
      attribute :author :string
      attribute :body, :string
      view :all # => emits :id and will return all comments
      view :by_author, emit_key: :author

      # Generates two functions:
      # * the by_author view above
      # * def find_by_author(author); end
      index_view :author

      # You can make compound keys by passing an array to :emit_key
      # this allow to query by read/unread comments
      view :by_read, emit_key: [:user_id, :read]
      # this allow to query by view_count
      view :by_view_count, emit_key: [:user_id, :view_count]

      validates_presence_of :author, :body
    end
```

You can use `Comment.find_by_author('name')` to obtain all the comments by
a particular author. The same thing, using the view directly would be:
`Comment.by_author(key: 'name')`

When using a compound key, the usage is the same, you just give the full key :

```ruby
   Comment.by_read(key: '["'+user_id+'",false]') # gives all unread comments for one particular user

   # or even a range !

   Comment.by_view_count(startkey: '["'+user_id+'",10]', endkey: '["'+user_id+'",20]') 
   
   # gives all comments that have been seen more than 10 times but less than 20
```
Check this couchbase help page to learn more on what's possible with compound keys : <https://developer.couchbase.com/documentation/server/3.x/admin/Views/views-translateSQL.html>

Ex : Compound keys allows to decide the order of the results, and you can reverse it by passing `descending: true`

```ruby
    class Comment < CouchbaseOrm::Base19
      self.ignored_properties = [:old_name] # ignore old_name property in the model
      self.properties_always_exists_in_document = true # use is null for nil value instead of not valued for performance purpose, only possible if all properties always exists in document
    end
```      
You can specify `properties_always_exists_in_document` to true if all properties always exists in document, this will allow to use `is null` instead of `not valued` for nil value, this will improve performance. 

WARNING: If a document exists without a property, the query will failed! So you must be sure that all documents have all properties.


## N1ql

Like views, it's possible to use N1QL to process some requests used for filtering results or ordering.

```ruby
    class Comment < CouchbaseOrm::Base
      attribute :author, :string
      attribute :body, :string
      n1ql :by_author, emit_key: :author

      # Generates two functions:
      # * the by_author view above
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

By default, `has_many` uses a view for association,
but you can define a `type` option to specify an association using N1QL instead:

  ```ruby
  class Comment < CouchbaseOrm::Base
      belongs_to :author
  end

  class Author < CouchbaseOrm::Base
      has_many :comments, type: :n1ql, dependent: :destroy
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
