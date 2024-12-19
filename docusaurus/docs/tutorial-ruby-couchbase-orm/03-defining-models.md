# Defining Models

In CouchbaseOrm, models are defined as Ruby classes that inherit from `CouchbaseOrm::Base`. Each model represents a document type in Couchbase Server and encapsulates the data and behavior of the objects in your application.

## 3.1. Creating a Model

To create a model, define a new class that inherits from `CouchbaseOrm::Base`. For example, let's create a `User` model:

```ruby
class User < CouchbaseOrm::Base
end
```

By convention, CouchbaseOrm uses the underscored, pluralized name of the class as the document type in Couchbase Server. In this case, the document type for the `User` model would be `users`.

## 3.2. Attribute Types

CouchbaseOrm supports various attribute types to define the structure and types of your model's data. You can specify the attributes of your model using the `attribute` method.

Here's an example of defining attributes in the `User` model:

```ruby
class User < CouchbaseOrm::Base
  attribute :email, :string
  attribute :name, :string
  attribute :age, :integer
  attribute :height, :float
  attribute :is_active, :boolean
  attribute :birth_date, :date
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
  attribute :appointment_time, :time
  attribute :hobbies, :array, type: :string
  attribute :metadata, type: Hash
  attribute :avatar, :binary

  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end
```

In this example, we define several attributes for the `User` model, each with a specific type. The supported attribute types in CouchbaseOrm include:

- `:string`: Represents a string value.
- `:integer`: Represents an integer value.
- `:float`: Represents a floating-point value.
- `:boolean`: Represents a boolean value.
- `:date`: Represents a date value.
- `:datetime`: Represents a date and time value.
- `:time`: Represents a time value.
- `:array`: Represents an array of values.
- `:binary`: Represents a binary data value.

- `Hash`: Represents a hash (dictionary) of key-value pairs.

CouchbaseOrm automatically handles the serialization and deserialization of these attribute types when storing and retrieving documents from Couchbase Server.

## 3.3. Attribute Options

In addition to specifying the attribute type, you can also provide additional options to customize the behavior of the attributes. Some commonly used options include:

- `default`: Specifies a default value for the attribute if no value is provided.


Here's an example of using attribute options:

```ruby
class User < CouchbaseOrm::Base
  attribute :name, :string, default: 'Unknown'
end
```

In this example, the `name` attribute has a default value of `'Unknown'`.
 <!-- the `email` attribute is aliased as `contact_email` in the document, and the `age` attribute is marked as read-only. -->

## 3.4. Timestamps

CouchbaseOrm provides built-in support for timestamp attributes. By default, if you define attributes named `created_at` and `updated_at` with the `:datetime` type, CouchbaseOrm will automatically populate these attributes with the current date and time when a document is created or updated. To enable this feature, add the `created_at` and `updated_at` attributes to your model.The fields are automatically updated when the document is saved.`document.save`

```ruby
class User < CouchbaseOrm::Base
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end
```

With these timestamp attributes defined, CouchbaseOrm will manage them automatically whenever a document is persisted or updated.

## 3.5. Callbacks

CouchbaseOrm supports lifecycle callbacks that allow you to execute code at certain points in a document's lifecycle. Callbacks can be used to perform actions before or after specific events, such as saving or updating a document.

Here are some commonly used callbacks:

- `before_create`: Runs before a new document is created.
- `after_create`: Runs after a new document is created.
- `before_save`: Runs before a document is saved (either created or updated).
- `after_save`: Runs after a document is saved (either created or updated).
- `before_update`: Runs before an existing document is updated.
- `after_update`: Runs after an existing document is updated.
- `before_destroy`: Runs before a document is destroyed.
- `after_destroy`: Runs after a document is destroyed.

To define a callback, use the corresponding callback method and provide a block or method name to be executed. For example:

```ruby
class Document < CouchbaseOrm::Base
  attribute :title, :string
  attribute :content, :string

  before_create :before_create_callback
  after_create :after_create_callback
  before_save :before_save_callback
  after_save :after_save_callback
  before_update :before_update_callback
  after_update :after_update_callback
  before_destroy :before_destroy_callback
  after_destroy :after_destroy_callback

  private

  def before_create_callback
    puts "Running before_create callback for #{title}"
  end

  def after_create_callback
    puts "Running after_create callback for #{title}"
  end

  def before_save_callback
    puts "Running before_save callback for #{title}"
  end

  def after_save_callback
    puts "Running after_save callback for #{title}"
  end

  def before_update_callback
    puts "Running before_update callback for #{title}"
  end

  def after_update_callback
    puts "Running after_update callback for #{title}"
  end

  def before_destroy_callback
    puts "Running before_destroy callback for #{title}"
  end

  def after_destroy_callback
    puts "Running after_destroy callback for #{title}"
  end
end
```

In this example, the `Document` model defines several callbacks that are triggered at different points in the document's lifecycle. The callback methods are implemented as private instance methods within the model class.

Callbacks allow you to encapsulate logic related to the document lifecycle and maintain a clean and organized codebase.

## 3.6. Validations

CouchbaseOrm includes built-in validation capabilities to ensure the integrity and validity of your data before persisting it to Couchbase Server. Validations help you enforce business rules and constraints on your models.

To define validations, use the `validates` method followed by the attribute name and the desired validation rules. For example:

```ruby
class Book < CouchbaseOrm::Base
  attribute :title, :string
  attribute :author, :string
  attribute :pages, :integer
  attribute :genre, :string
  attribute :email, :string

  validates_presence_of :title
  validates :author, presence: true
  validates :pages, numericality: { greater_than: 0 }
  validates :genre, inclusion: { in: %w[Fiction Non-Fiction] }
  validates :author, format: { with: /\A[a-zA-Z]+\z/, message: 'only allows letters' }
  validates :pages, length: { maximum: 500 }
  validates :genre, exclusion: { in: %w[Science-Fiction] }
  validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }

  validate :custom_validation

  private

  ...
end
```

In this example, we define several validations for the `User` model:

- The `name` attribute must be present.
- The `email` attribute must match a specific format (a valid email address).
- The `age` attribute must be a number greater than or equal to 18.

CouchbaseOrm provides a wide range of built-in validation helpers, such as:

- `presence`: Ensures that the attribute is not blank.
- `validates_presence_of`: An alias for `presence`.
<!-- - `uniqueness`: Ensures that the attribute value is unique among all documents. -->
- `format`: Validates the attribute value against a regular expression.
- `length`: Validates the length of the attribute value.
- `numericality`: Validates that the attribute value is a valid number.
- `inclusion`: Ensures that the attribute value is included in a given set.
- `exclusion`: Ensures that the attribute value is not included in a given set.


You can also define custom validation methods by adding methods to your model class and using the `validate` method to trigger them. For example:

```ruby
class Book < CouchbaseOrm::Base
  attribute :title, :string
  ...

  validate :custom_validation

  private

  def custom_validation
    puts 'Running custom validation...'
    if title&.include?('Funny')
      errors.add(:title, 'should not contain the word "Funny"')
    else
      # print the title
      puts "Title: #{title}"
      puts 'Custom validation passed'
    end
  end
end
```

In this example, the `custom_validation` method is called during the validation process, and if `some_condition` is met, an error is added to the model's `errors` collection.

Validations are automatically run when saving a document. If any validations fail, the save operation will be aborted, and the model's `errors` collection will contain the validation error messages.

By leveraging validations, you can ensure the quality and consistency of your data before it is persisted to Couchbase Server.

With the model definition covered, including attributes, callbacks, and validations, you're ready to start querying and persisting data using CouchbaseOrm. In the next section, we'll explore the querying capabilities of CouchbaseOrm and how to retrieve data from Couchbase Server efficiently.
