# Querying

CouchbaseOrm provides a powerful and expressive query interface for retrieving data from Couchbase Server. With CouchbaseOrm, you can easily construct queries using a fluent and intuitive API that resembles the querying capabilities of ActiveRecord.

## 4.1. Finding Records

CouchbaseOrm offers various methods to find records based on different criteria. Here are some commonly used methods:

- `find`: Finds a record by its primary key (ID).
- `find_by`: Finds the first record that matches the specified attribute-value pair.
- `where`: Retrieves records that match the specified conditions.

Here are some examples of finding records:

```ruby
# Define an Author model
class Author < CouchbaseOrm::Base
  attribute :name, :string
  attribute :age, :integer
  attribute :active, :boolean, default: true

  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 18 }

end

# Create new authors
author1 = Author.new(name: 'John Doe', age: 30, active: true)
author2 = Author.new(name: 'Jane Smith', age: 25, active: false)
author3 = Author.new(name: 'Alice Brown', age: 40, active: true)
author4 = Author.new(name: 'Bob Johnson', age: 17, active: true)

# Save authors
author1.save
author2.save
author3.save
author4.save

# Find authors by ID
puts Author.find(author1.id).inspect

# Find the first author with a specific name
puts Author.find_by(name: 'John Doe').inspect

# Where
puts Author.where(active: true).to_a.inspect
```

## 4.2. Where Clauses

The `where` method allows you to specify conditions to filter the records based on attribute values. You can chain multiple `where` clauses together to build more complex queries.

```ruby
# Where
puts Author.where(active: true).where('age >= 30').to_a.inspect

puts Author.where("name like '%John%'").to_a.inspect
```

CouchbaseOrm supports various comparison operators and placeholders in the `where` clauses, such as `=`, `>`, `<`, `>=`, `<=`, `LIKE`, and more.

## 4.3. Ordering

You can specify the order in which the retrieved records should be sorted using the `order` method. Pass the attribute name and the desired sort direction (`:asc` for ascending, `:desc` for descending).

```ruby
# Order authors by name
puts Author.order(:name).to_a.inspect

# Order authors by age in descending order
puts Author.order(age: :desc).to_a.inspect
```

You can also chain multiple `order` clauses to sort by multiple attributes.


Scopes provide a clean and DRY way to encapsulate commonly used query conditions.

## 4.4. Pluck

The `pluck` method allows you to retrieve specific attributes from the matched records instead of loading the entire objects. It returns an array of values for the specified attributes.

```ruby
# Pluck names of all authors
puts Author.order(:name).pluck(:name).inspect
```

## 4.5. Destroying Records

To delete multiple records that match specific conditions, you can use the `.each(&:destroy)` method. It deletes the records from the database and returns the number of records deleted.

- `:destroy`: Deletes a single record.
- `delete_all`: Deletes all records that match the specified conditions.

```ruby
# Destroy all inactive authors
Author.where(active: false).each(&:destroy)

# Destroy all authors who are inactive
Author.where(active: false).delete_all

```


These are just a few examples of the querying capabilities provided by CouchbaseOrm. You can combine these methods in various ways to construct complex and specific queries based on your application's requirements.

In the next section, we'll explore how to use CouchbaseOrm to create, update, and delete records in Couchbase Server.

## 4.6. Scopes

Scopes allow you to define reusable query snippets that can be chained with other query methods. Scopes are defined as class methods within your model.

```ruby
# Define a Comment model
class Comment < CouchbaseOrm::Base
  attribute :title, :string
  attribute :author, :string
  attribute :category, :string
  attribute :ratings, :integer

  def self.by_author(author)
    where(author: author)
  end

  def self.highly_rated
    where('ratings > 3')
  end

  def self.in_category(category)
    where(category: category)
  end
end


# Create some comments
comment1 = Comment.new(title: 'First Comment', author: 'Anne McCaffrey', category: 'S-F', ratings: 5)
comment2 = Comment.new(title: 'Second Comment', author: 'Anne McCaffrey', category: 'S-F', ratings: 4)
comment3 = Comment.new(title: 'Third Comment', author: 'Anne McCaffrey', category: 'S-F', ratings: 3)
comment4 = Comment.new(title: 'Fourth Comment', author: 'Anne McCaffrey', category: 'S-F', ratings: 2)

# Save the comments
comment1.save
comment2.save
comment3.save
comment4.save

# Example usage of scopes
comments = Comment.by_author("Anne McCaffrey").in_category('S-F').highly_rated.order(:title).limit(10)

# Iterate over the comments
comments.each do |comment|
  puts "Title: #{comment.title}, Author: #{comment.author}, Category: #{comment.category}, Ratings: #{comment.ratings}"
end
```
