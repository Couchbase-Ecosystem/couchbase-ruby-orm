# Views (aka Map/Reduce indexes)

Views are a powerful feature in Couchbase that allow you to define map functions to extract and emit specific data from your documents. The Ruby Couchbase ORM provides a convenient way to define and query views within your Ruby application.

## 8.1 Defining Views

To define a view in your Ruby Couchbase ORM model, you can use the `view` method followed by the view name and options. Here's an example:

```ruby
class Factory < CouchbaseOrm::Base
  attribute :name, type: String
  attribute :location, type: String
  attribute :established_year, type: Integer
  attribute :active, type: Boolean

  view :by_name, emit_key: :name
  view :by_location, emit_key: :location
  view :by_established_year, emit_key: :established_year
  view :by_active, emit_key: :active
end
```

In this example, we define four views for the `Factory` model:
- `by_name`: Emits the `name` attribute as the key.
- `by_location`: Emits the `location` attribute as the key.
- `by_established_year`: Emits the `established_year` attribute as the key.
- `by_active`: Emits the `active` attribute as the key.

The `emit_key` option specifies the attribute to use as the key for the view.

## 8.2 Custom Map Functions

You can also define custom map functions for your views using the `map` option. This allows you to emit custom keys and values based on your specific requirements. Here's an example:

```ruby
view :by_name_and_location,
  map: %{
    function(doc) {
      if (doc.type === "factory") {
        emit([doc.name, doc.location], null);
      }
    }
  }
```

In this example, we define a view named `by_name_and_location` that emits a composite key consisting of the `name` and `location` attributes.

## 8.3 Querying Views

Once you have defined your views, you can query them using the corresponding view methods. The view methods are automatically generated based on the view names. Here are some examples:

```ruby
# Query factories by name
Factory.by_name(key: 'Factory A').each do |factory|
  puts "- #{factory.name}"
end

# Query factories by location
Factory.by_location(key: 'City X').each do |factory|
  puts "- #{factory.name}"
end

# Query factories by established year
Factory.by_established_year(key: 2010).each do |factory|
  puts "- #{factory.name}"
end

# Query active factories
Factory.by_active(key: true).each do |factory|
  puts "- #{factory.name}"
end
```

These examples demonstrate how to query views based on specific keys using the generated view methods.

## 8.4 Indexing Views

In this section, let's explore the `index_view` function and the methods it generates for the `location` attribute.

Here's an updated version of the `Factory` model using `index_view` for the `location` attribute:

```ruby
class Factory < CouchbaseOrm::Base
  attribute :name, type: String
  attribute :location, type: String
  attribute :established_year, type: Integer
  attribute :active, type: Boolean

  view :by_name, emit_key: :name
  index_view :location
  view :by_established_year, emit_key: :established_year
  view :by_active, emit_key: :active

  view :by_name_and_location,
    map: %{
      function(doc) {
        if (doc.type === "factory") {
          emit([doc.name, doc.location], null);
        }
      }
    }

  view :by_established_year_range,
    map: %{
      function(doc) {
        if (doc.type === "factory" && doc.established_year) {
          emit(doc.established_year, null);
        }
      }
    }
end
```

In this updated code, we replaced `view :by_location, emit_key: :location` with `index_view :location`. The `index_view` function generates two methods for querying based on the `location` attribute:

1. `find_by_location(location)`: This method allows you to find factories by a specific location. It returns an array of factories that match the given location.

2. `by_location(key: location)`: This method is similar to `find_by_location` but returns a `CouchbaseOrm::ResultsProxy` object, which provides an enumerable interface to access the view results.

Now, let's see how we can use these generated methods to query factories by location:

```ruby
# Find factories by location using find_by_location
factories = Factory.find_by_location('City X')
factories.each do |factory|
  puts "- #{factory.name} (#{factory.location})"
end

# Find factories by location using by_location
Factory.by_location(key: 'City X').each do |factory|
  puts "- #{factory.name} (#{factory.location})"
end
```

Both `find_by_location` and `by_location` achieve the same result of finding factories by a specific location. The difference is that `find_by_location` returns an array of factories directly, while `by_location` returns a `CouchbaseOrm::ResultsProxy` object that you can further chain or iterate over.

Using `index_view` provides a convenient way to generate commonly used query methods for a specific attribute. It simplifies the process of querying based on that attribute and enhances the readability of your code.

<!-- ## 8.5 Range Queries (Experimental)

You can perform range queries on views by specifying the `startkey` and `endkey` options. Here's an example:

```ruby
# Query factories established between 2005 and 2015
Factory.by_established_year_range(startkey: 2005, endkey: 2015).each do |factory|
  puts "- #{factory.name} (#{factory.established_year})"
end
```

In this example, we query the `by_established_year_range` view to retrieve factories established between 2005 and 2015. -->

## 8.5 Conclusion

Views in the Ruby Couchbase ORM provide a powerful way to define and query data based on specific attributes and custom map functions. By defining views, you can easily retrieve subsets of your data and perform efficient queries based on your application's requirements.

Remember to ensure that your design documents are up to date by calling `ensure_design_document!` on your models before running queries.

With the flexibility and ease of use provided by the Ruby Couchbase ORM's view functionality, you can efficiently query and retrieve data from your Couchbase database.