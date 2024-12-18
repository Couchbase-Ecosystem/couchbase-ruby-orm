# Persistence

CouchbaseOrm provides a simple and intuitive way to persist data to Couchbase Server. With CouchbaseOrm, you can easily create, update, save, and destroy records using a set of built-in methods.

## 5.1. Creating Records

To create a new record, you can instantiate a new instance of your model class and then call the `save` method to persist it to the database.

```ruby
class Task < CouchbaseOrm::Base
  attribute :title, :string
  attribute :description, :string
  attribute :completed, :boolean, default: false
end

task = Task.new(title: 'Task 1', description: 'Description of Task 1')
task.save
```

Alternatively, you can use the `create` method to create a new record in a single step:

```ruby
task = Task.create(title: 'Task 1', description: 'Description of Task 1')
```


The `create` method instantiates a new instance of the model, sets the attributes, and saves it to the database.

## 5.2. Saving Records

The `save` method is used to persist a record to the database, whether it's a new record or an existing one with modifications.

```ruby
# Update an existing task
task = Task.create(title: 'Task 2', description: 'Description of Task 2')
task.description = 'Updated description of Task 2'
task.save
```



If the record is new (i.e., it doesn't have an ID), `save` will create a new document in Couchbase Server. If the record already exists, `save` will update the existing document with the modified attributes.

## 5.3. Updating Records

To update an existing record, you can modify its attributes and then call the `save` method to persist the changes.

```ruby
# Update specific fields of a task
task = Task.create(title: 'Task 3', description: 'Description of Task 3')
task.update(description: 'Updated description of Task 3', completed: true)
```

CouchbaseOrm automatically tracks the changes made to the attributes and updates only the modified fields in the database.

## 5.4. Destroying Records

To delete a record from the database, you can call the `destroy` method on an instance of your model.

```ruby
user = User.find('user_id_123')
user.destroy
```

The `destroy` method removes the corresponding document from Couchbase Server and freezes the model instance to prevent further modifications.


## 5.5. Callbacks

As mentioned in the previous section on defining models, CouchbaseOrm supports lifecycle callbacks that allow you to execute code at certain points in a record's persistence lifecycle.

Callbacks can be used to perform actions before or after specific events, such as saving or updating a record. Some commonly used callbacks include `before_save`, `after_save`, `before_create`, `after_create`, `before_update`, `after_update`, `before_destroy`, and `after_destroy`.

```ruby
class User < CouchbaseOrm::Base
  before_save :encrypt_password
  after_create :send_welcome_email

  private

  def encrypt_password
    self.password = encrypt(password) if password_changed?
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
  end
end
```

In this example, the `encrypt_password` callback is executed before saving a user record, encrypting the password if it has been changed. The `send_welcome_email` callback is executed after creating a new user record, sending a welcome email to the user.

Callbacks provide a way to encapsulate and reuse common logic related to the persistence lifecycle of your records.
