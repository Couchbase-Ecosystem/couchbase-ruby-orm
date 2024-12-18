# Encryption

CouchbaseOrm provides built-in support for encrypting sensitive data stored in your Couchbase documents. Encryption allows you to protect confidential information, such as personal data or financial details, by encrypting the values before storing them in the database and decrypting them when retrieving the data.

## 11.1. Encrypted Attributes

To mark an attribute as encrypted, you can use the `:encrypted` type when defining the attribute in your model.

```ruby
# Define the Bank model with an encrypted attribute
class Bank < CouchbaseOrm::Base
  attribute :name, :string
  attribute :account_number, :encrypted
  attribute :routing_number, :encrypted, alg: "3DES"
end
```

In this example, the `account_number` and `routing_number` attributes are marked as encrypted. By default, CouchbaseOrm uses the default `CB_MOBILE_CUSTOM` encryption algorithm for encrypting the values. You can specify a different encryption algorithm by providing the `alg` option.

```plaintext
{
  "name": "Test Bank",
  "encrypted$account_number": {
    "alg": "CB_MOBILE_CUSTOM",
    "ciphertext": "MTIzNDU2Nzg5"
  },
  "encrypted$routing_number": {
    "alg": "3DES",
    "ciphertext": "OTg3NjU0MzIx"
  },
  "type": "bank"
}
```

When a document is saved, CouchbaseOrm stores the encrypted values in the document with a prefix of `encrypted$`. The encrypted values are stored as JSON objects containing the encryption algorithm (`alg`) and the ciphertext (`ciphertext`) of the encrypted value.

You can assign values to encrypted attributes just like any other attribute.

```ruby
bank = Bank.new(name: 'My Bank', account_number: '123456789', routing_number: '987654321')
```

When the document is saved, CouchbaseOrm encrypts the value of `ssn` using the configured encryption key.

## 11.2. Encryption Process 

```ruby
require 'base64'
require 'logger'

Bank.all.each(&:destroy)

# Method to print serialized attributes
def expect_serialized_attributes(bank)
  serialized_attrs = bank.send(:serialized_attributes)
  serialized_attrs.each do |key, value|
    puts "#{key}: #{value}"
  end
  json_attrs = JSON.parse(bank.to_json)
  json_attrs.each do |key, value|
    puts "#{key}: #{value}"
  end
  bank.as_json.each do |key, value|
    puts "#{key}: #{value}"
  end
end

# Create a new bank record with encrypted attributes
bank = Bank.new(
  name: "Test Bank",
  account_number: Base64.strict_encode64("123456789"),
  routing_number: Base64.strict_encode64("987654321")
)

# Print serialized attributes before saving
expect_serialized_attributes(bank)

# Save the bank record to Couchbase
bank.save!

# Reload the bank record from Couchbase
bank.reload

# Print serialized attributes after reloading
expect_serialized_attributes(bank)

# Find the bank record by ID
found_bank = Bank.find(bank.id)

# Print serialized attributes after finding
expect_serialized_attributes(found_bank)
```

## 11.3. Encryption and Decryption Process

When an encrypted attribute is assigned a value, CouchbaseOrm encrypts the value using the configured encryption key and algorithm. The encrypted value is then stored in the Couchbase document.

When retrieving a document with encrypted attributes, CouchbaseOrm automatically decrypts the encrypted values using the same encryption key and algorithm. The decrypted values are then accessible through the model's attributes.

It's important to keep the encryption key secure and protect it from unauthorized access. If the encryption key is compromised, the encrypted data can be decrypted by anyone who obtains the key.

## 11.4. Considerations and Best Practices

When using encryption in CouchbaseOrm, consider the following best practices:

- Keep the encryption key secure and protect it from unauthorized access. Store the key securely and avoid committing it to version control systems.
- Use strong and unique encryption keys for each environment (development, staging, production) to prevent cross-environment access to encrypted data.
- Be cautious when querying encrypted attributes as it may impact performance. Consider indexing encrypted attributes separately if frequent querying is required.
- If you need to search or query encrypted data frequently, consider using a separate encrypted search index or a dedicated encryption service.
- Ensure that the encryption key is properly rotated and managed. If the encryption key is compromised, you should generate a new key and re-encrypt the affected data.

Encryption is a powerful tool for protecting sensitive data, but it should be used judiciously. Encrypting every attribute in your model may not be necessary or practical. Focus on encrypting the most sensitive and confidential data while balancing the trade-offs between security and performance.

In the next section, we'll explore logging in CouchbaseOrm and how you can configure and customize logging to monitor and debug your application.
