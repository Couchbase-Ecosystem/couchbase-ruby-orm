# Nested Documents

CouchbaseOrm supports nested documents, which allow you to store complex, hierarchical data structures within a single Couchbase document. Nested documents are useful when you have related data that you want to store together with the parent document for performance or consistency reasons.

## 9.1. Defining Nested Documents

To define an nested document, you create a new class that inherits from `CouchbaseOrm::NestedDocument`.

```ruby
class Part < CouchbaseOrm::NestedDocument
  attribute :name, :string
  attribute :manufacturer, :string
end

# Define the Car model with a nested Part document
class Car < CouchbaseOrm::Base
  attribute :make, :string
  attribute :model, :string
  attribute :year, :integer
  attribute :parts, :array, type: Part

  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true
end

```

In this example, we define a `Car` model with a nested `Part` document. The `Part` class inherits from `CouchbaseOrm::NestedDocument` and defines attributes for `name` and `manufacturer`. The `Car` model has an `parts` attribute that is an array of `Part` nested documents.

## 9.2. Embedding Documents

To embed a document within a parent document, you can assign an instance of the nested document class to the corresponding attribute.

```ruby
# Create a new car with nested parts
car = Car.new(
  make: 'Toyota',
  model: 'Corolla',
  year: 2022,
  parts: [
    Part.new(name: 'Engine', manufacturer: 'Toyota Motors'),
    Part.new(name: 'Transmission', manufacturer: 'Toyota Motors')
  ]
)
car.save
```

When saving the parent document (`Car`), CouchbaseOrm serializes the nested `Part` documents and stores them within the parent document. This allows you to retrieve the entire data structure with a single query.

## 9.3. Accessing Nested Documents

To access an nested document, you can simply call the corresponding attribute on the parent document.

```ruby
toyota_cars = Car.where(make: 'Toyota')
```

CouchbaseOrm automatically deserializes the nested document and returns an instance of the nested document class.

## 9.4. Updating Nested Documents

To update an nested document, you can modify the attributes of the nested document instance and save the parent document.

```ruby
engine_part = car.parts.find { |part| part.name == 'Engine' }
engine_part.manufacturer = 'Toyota Industries'
car.save
```

CouchbaseOrm will serialize the updated nested document and save it along with the parent document.

## 9.5. Embedding Multiple Documents

You can also embed multiple documents within a parent document using an array attribute.

```ruby
car = Car.new(
  make: 'Toyota',
  model: 'Corolla',
  year: 2022,
  parts: [
    Part.new(name: 'Engine', manufacturer: 'Toyota Motors'),
    Part.new(name: 'Transmission', manufacturer: 'Toyota Motors')
  ]
)
car.save
```

In this example, the `Car` model has an `parts` attribute that is an array of `Part` nested documents. You can embed multiple `Part` documents within a single `Car` document, allowing you to store related data together.

## 9.6. Querying Nested Documents

CouchbaseOrm allows you to query nested documents using dot notation and attribute conditions.

```ruby
cars_by_part_manufacturer = Car.where("ANY part IN parts SATISFIES part.manufacturer = 'Toyota Industries' END")
```

This query retrieves all the `Car` documents where at least one `Part` document has a `manufacturer` attribute equal to `'Toyota Industries'`. You can use dot notation to access nested document attributes within the query condition.

## 9.7. Validating Nested Documents

CouchbaseOrm allows you to validate nested documents along with the parent document.

```ruby
class Part < CouchbaseOrm::NestedDocument
  attribute :name, :string
  attribute :manufacturer, :string

  validates :name, presence: true
  validates :manufacturer, presence: true
end

class Car < CouchbaseOrm::Base
  attribute :make, :string
  attribute :model, :string
  attribute :year, :integer
  attribute :parts, :array, type: Part

  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true
  validates :parts, presence: true
end


```

In this example, we define validations for the `Part` nested document, ensuring that the `name` and `manufacturer` attributes are present. We also add validations to the `Car` model to ensure that the `make`, `model`, `year`, and `parts` attributes are present.

When saving a `Car` document, CouchbaseOrm will validate both the parent document and the nested `Part` documents. If any validation fails, the parent document will not be saved, and validation errors will be added to the parent document.

Nested documents provide a powerful way to model complex data structures and relationships within a single Couchbase document. They allow you to store related data together, improving performance and reducing the need for separate queries to retrieve associated data.

However, it's important to consider the trade-offs when using nested documents. Embedding too much data within a single document can lead to large document sizes and potential performance issues. It's recommended to use nested documents judiciously and to consider the access patterns and data relationships of your application.

In the next section, we'll explore enums in CouchbaseOrm and how they can be used to define a fixed set of values for an attribute.
