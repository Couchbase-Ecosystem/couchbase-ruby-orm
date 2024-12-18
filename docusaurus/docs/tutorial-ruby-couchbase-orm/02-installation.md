# Installation

Installing Couchbase ORM is a straightforward process. In this section, we'll guide you through the prerequisites and the step-by-step installation procedure.

## 2.1. Prerequisites

Before installing Couchbase ORM, ensure that you have the following prerequisites in place:

1. **Ruby**: Couchbase ORM requires Ruby version 2.7 or higher. You can check your Ruby version by running the following command in your terminal:

   ```sh
   ruby -v
   ```

   If you don't have Ruby installed or your version is older than 2.7, you can install the latest version from the official Ruby website: [https://www.ruby-lang.org](https://www.ruby-lang.org)

2. **Couchbase Server**: Couchbase ORM works with Couchbase Server, a NoSQL database. Make sure you have Couchbase Server installed and running on your system. You can download Couchbase Server from the official website: [https://www.couchbase.com/downloads](https://www.couchbase.com/downloads)

   Follow the installation instructions specific to your operating system to set up Couchbase Server.

3. **Bundler** (optional): Bundler is a dependency management tool for Ruby. While not strictly required, it is recommended to use Bundler to manage your Ruby project's dependencies. You can install Bundler by running the following command:

   ```sh
   gem install bundler
   ```

With these prerequisites in place, you're ready to install Couchbase ORM.

## 2.2. Installing Couchbase ORM

To install Couchbase ORM, you have a couple of options:

1. **Using Bundler** (recommended): If you're using Bundler to manage your project's dependencies, add the following line to your `Gemfile`:

   ```ruby
   gem 'couchbase-orm', git: 'https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm'
   ```

   Then, run the following command to install the gem:

   ```sh
   bundle install
   ```

   Bundler will take care of installing Couchbase ORM and its dependencies.

2. **Using RubyGems**: If you're not using Bundler, you can install Couchbase ORM directly using RubyGems. Run the following command in your terminal:

   ```sh
   gem install couchbase-orm
   ```

   This command will download and install the Couchbase ORM gem along with its dependencies.

After the installation is complete, you're ready to configure Couchbase ORM to connect to your Couchbase Server instance.

## 2.3. Configuring Couchbase Connection

To use Couchbase ORM in your Ruby application, you need to configure the connection settings for your Couchbase Server instance. Couchbase ORM provides a simple way to configure the connection.

1. **Rails Applications**:

   If you're using Couchbase ORM in a Rails application, create a new configuration file named `couchbase.yml` in the `config` directory of your Rails project. Add the following content to the file:

   ```yaml
   development:
     connection_string: couchbase://localhost
     bucket: my_app_development
     username: my_username
     password: my_password

   test:
     connection_string: couchbase://localhost
     bucket: my_app_test
     username: my_username
     password: my_password

    production:
      connection_string: <%= ENV['COUCHBASE_CONNECTION_STRING'] %>
      bucket: <%= ENV['COUCHBASE_BUCKET'] %>
      username: <%= ENV['COUCHBASE_USER'] %>
      password: <%= ENV['COUCHBASE_PASSWORD'] %>
   ```

   Replace the values for `connection_string`, `bucket`, `username`, and `password` with your actual Couchbase Server connection details.

   Couchbase ORM will automatically load the configuration based on the current Rails environment.

   You can also set the connection details using environment variables in the production environment to avoid storing sensitive information in the source code.

2. **Non-Rails Applications**:

   For non-Rails applications, you can configure the connection settings programmatically. Add the following code to your application's initialization file or before you start using Couchbase ORM:

   ```ruby
   Couchbase ORM.configure do |config|
     config.connection_string = 'couchbase://localhost'
     config.bucket = 'travel-sample'
     config.username = 'Administrator'
     config.password = 'password'
   end
   ```

   Replace the values for `connection_string`, `bucket`, `username`, and `password` with your actual Couchbase Server connection details.

With the connection configured, you're now ready to start defining your models and interacting with Couchbase Server using Couchbase ORM.

In the next section, we'll explore how to define models in Couchbase ORM and work with the basic CRUD operations.
