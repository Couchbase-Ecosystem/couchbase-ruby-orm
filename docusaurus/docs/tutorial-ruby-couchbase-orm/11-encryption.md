# Encryption

CouchbaseOrm provides built-in support for storing encrypted data in your Couchbase documents using a structured format. The `:encrypted` type provides a standardized storage format compatible with Couchbase Lite's field-level encryption, but **does not perform encryption/decryption itself**. Your application is responsible for encrypting data before storing it and decrypting it after retrieval.

## 11.1. Encrypted Attributes

To mark an attribute as encrypted, you can use the `:encrypted` type when defining the attribute in your model.

```ruby
# Define the Bank model with encrypted attributes
class Bank < CouchbaseOrm::Base
  attribute :name, :string
  attribute :account_number, :encrypted
  attribute :routing_number, :encrypted, alg: "3DES"
end
```

In this example, the `account_number` and `routing_number` attributes are marked as encrypted. The `alg` option specifies the encryption algorithm identifier that will be stored in the document metadata (default is `"CB_MOBILE_CUSTOM"`). This identifier is for documentation purposes and Couchbase Lite compatibility - CouchbaseOrm does not use it for actual encryption.

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

When a document is saved, CouchbaseOrm stores encrypted attributes in the document with a prefix of `encrypted$`. The values are stored as JSON objects containing the encryption algorithm identifier (`alg`) and the ciphertext (`ciphertext`).

**Important**: You must provide **pre-encrypted** values to encrypted attributes. CouchbaseOrm stores these values as-is in the `ciphertext` field without performing any encryption.

```ruby
# You must encrypt the data BEFORE assigning it to the attribute
require 'base64'

# Assuming you have an encryption method (e.g., AES, Tanker, etc.)
encrypted_account = MyEncryptor.encrypt('123456789')
encrypted_routing = MyEncryptor.encrypt('987654321')

# Values must be Base64-encoded strings
bank = Bank.new(
  name: 'My Bank',
  account_number: Base64.strict_encode64(encrypted_account),
  routing_number: Base64.strict_encode64(encrypted_routing)
)
```

## 11.2. Complete Example with Encryption

Here's a complete example showing how to handle encryption in your application:

```ruby
require 'base64'
require 'openssl'

# Example encryption helper (you should use a proper encryption library)
class SimpleEncryptor
  def self.encrypt(plaintext)
    # This is a simplified example - use a proper encryption library in production
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = ENV['ENCRYPTION_KEY'] # Store securely, never commit to git
    cipher.iv = iv = cipher.random_iv

    encrypted = cipher.update(plaintext) + cipher.final
    # Prepend IV for decryption (in real implementation, handle this properly)
    iv + encrypted
  end

  def self.decrypt(ciphertext_with_iv)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = ENV['ENCRYPTION_KEY']

    # Extract IV and ciphertext
    iv = ciphertext_with_iv[0..15]
    ciphertext = ciphertext_with_iv[16..]

    cipher.iv = iv
    cipher.update(ciphertext) + cipher.final
  end
end

# Create a bank record with encrypted attributes
plaintext_account = "123456789"
plaintext_routing = "987654321"

# 1. Encrypt the sensitive data
encrypted_account = SimpleEncryptor.encrypt(plaintext_account)
encrypted_routing = SimpleEncryptor.encrypt(plaintext_routing)

# 2. Encode as Base64 for storage
bank = Bank.new(
  name: "Test Bank",
  account_number: Base64.strict_encode64(encrypted_account),
  routing_number: Base64.strict_encode64(encrypted_routing)
)

# 3. Save to Couchbase
bank.save!

# 4. Retrieve and decrypt
found_bank = Bank.find(bank.id)

# 5. Decode Base64 and decrypt
account_encrypted = Base64.strict_decode64(found_bank.account_number)
routing_encrypted = Base64.strict_decode64(found_bank.routing_number)

decrypted_account = SimpleEncryptor.decrypt(account_encrypted)
decrypted_routing = SimpleEncryptor.decrypt(routing_encrypted)

puts "Decrypted account: #{decrypted_account}"  # => "123456789"
puts "Decrypted routing: #{decrypted_routing}"  # => "987654321"
```

## 11.3. Storage Format

CouchbaseOrm handles the storage format for encrypted attributes but does not perform encryption/decryption. Here's what happens:

**When saving:**
1. You assign a Base64-encoded ciphertext to the encrypted attribute
2. CouchbaseOrm wraps it in the `encrypted$` format with `alg` and `ciphertext` fields
3. The document is stored in Couchbase with this structure

**When loading:**
1. CouchbaseOrm reads the document from Couchbase
2. It unwraps the `encrypted$` format and extracts the `ciphertext` value
3. The Base64-encoded ciphertext is assigned to the attribute
4. Your application must decode and decrypt the value

**Key Points:**
- CouchbaseOrm does **not** require or use any encryption key
- The `alg` field is purely informational (for compatibility with Couchbase Lite)
- All actual encryption/decryption is your application's responsibility
- Values must be valid Base64-encoded strings

## 11.4. Considerations and Best Practices

When using encrypted attributes in CouchbaseOrm, consider the following best practices:

### Security
- **Encryption is your responsibility**: CouchbaseOrm only provides the storage format. Choose a robust encryption library (e.g., `rbnacl`, `openssl`, or a service like AWS KMS)
- **Key management**: Store encryption keys securely using environment variables, secret managers (AWS Secrets Manager, HashiCorp Vault), or key management services
- **Never commit keys**: Keep encryption keys out of version control systems
- **Key rotation**: Implement a key rotation strategy and maintain the ability to decrypt data encrypted with old keys
- **Use authenticated encryption**: Prefer AEAD modes (like AES-GCM) that provide both confidentiality and integrity

### Performance and Querying
- **Cannot query encrypted fields**: Encrypted attributes cannot be used in WHERE clauses or indexed effectively
- **Consider searchable encryption**: If you need to search encrypted data, investigate specialized solutions like searchable encryption schemes or external encrypted search indexes
- **Selective encryption**: Only encrypt truly sensitive fields to minimize performance overhead

### Implementation Patterns
- **Wrap in accessors**: Create getter/setter methods that automatically handle encryption/decryption:
  ```ruby
  class Bank < CouchbaseOrm::Base
    attribute :account_number, :encrypted

    def account_number=(plaintext)
      encrypted = MyEncryptor.encrypt(plaintext)
      super(Base64.strict_encode64(encrypted))
    end

    def account_number
      encrypted = Base64.strict_decode64(super)
      MyEncryptor.decrypt(encrypted)
    end
  end
  ```

- **Separate concerns**: Consider using a concern or module to encapsulate encryption logic:
  ```ruby
  module EncryptedAttributes
    def encrypted_attribute(name)
      define_method("#{name}=") do |plaintext|
        encrypted = MyEncryptor.encrypt(plaintext)
        super(Base64.strict_encode64(encrypted))
      end

      define_method(name) do
        encrypted = Base64.strict_decode64(super())
        MyEncryptor.decrypt(encrypted)
      end
    end
  end
  ```

### Compatibility
- The `encrypted$` format is compatible with Couchbase Lite's field-level encryption
- The `alg` field helps document which encryption algorithm was used, aiding in key rotation and auditing
- Ensure your encryption implementation is compatible across all platforms that access the data (web, mobile, etc.)

Encryption is a powerful tool for protecting sensitive data, but it should be used judiciously. Focus on encrypting the most sensitive and confidential data while balancing the trade-offs between security, performance, and functionality.

In the next section, we'll explore logging in CouchbaseOrm and how you can configure and customize logging to monitor and debug your application.
