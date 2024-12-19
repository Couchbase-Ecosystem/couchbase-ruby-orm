# Introduction

Welcome to the documentation for Couchbase ORM, an Object-Relational Mapping (ORM) library for Ruby that simplifies interactions with Couchbase Server. This guide will walk you through the features and usage of Couchbase ORM, helping you build efficient and scalable Ruby applications with Couchbase.

## 1.1. What is Couchbase ORM?

Couchbase ORM is a Ruby library that provides an ActiveRecord-like interface for working with Couchbase Server, a highly scalable and performant NoSQL database. It allows you to define your application's data models as Ruby classes and interact with the database using a familiar and intuitive API.

With Couchbase ORM, you can:

- Define your data models and their relationships
- Perform CRUD (Create, Read, Update, Delete) operations on your models
- Query your data using a flexible and expressive query language
- Use Couchbase-specific features like N1QL queries and views
- Implement advanced features such as data validation, callbacks, and associations

Couchbase ORM abstracts away the low-level details of interacting with Couchbase Server, enabling you to focus on writing business logic and building great applications.

## 1.2. Key Features

Couchbase ORM offers a wide range of features to make working with Couchbase Server a breeze. Some of the key features include:

1. **ActiveModel Compliance**: Couchbase ORM follows the ActiveModel API, providing a familiar interface for developers who have worked with ActiveRecord or other ActiveModel-compliant libraries.

2. **Attribute Definition**: Easily define your model's attributes and their types using a simple and intuitive DSL.

3. **Querying**: Use a powerful and expressive query language to retrieve data from Couchbase Server. Couchbase ORM supports a wide range of query options, including filtering, ordering, limiting, and more.

4. **Persistence**: Perform CRUD operations on your models with simple and intuitive methods like `save`, `create`, `update`, and `destroy`.

5. **Associations**: Define relationships between your models, such as one-to-many and many-to-many, using simple declarations.

6. **Validations**: Validate your model's data before persisting it to the database using a variety of built-in validators or custom validation methods.

7. **Callbacks**: Define callbacks to execute code before or after certain events, such as saving or updating a model.

8. **N1QL Queries**: Execute N1QL queries directly from your Ruby code and map the results to your models.

9. **Views**: Create and query Couchbase views to efficiently retrieve data based on specific criteria.

10. **Nested Documents**: Embed related documents within a parent document for denormalized data modeling.

These are just a few of the many features offered by Couchbase ORM. Throughout this documentation, we'll explore these features in-depth and provide examples of how to use them in your Ruby applications.

## 1.3. Getting Started

To get started with Couchbase ORM, you'll need to have Ruby and Couchbase Server installed on your system. Once you have the prerequisites in place, you can install the Couchbase ORM gem and start building your application.

In the next section, we'll walk through the installation process and show you how to configure Couchbase ORM to connect to your Couchbase Server instance.
