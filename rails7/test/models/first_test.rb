ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)
require 'rails/test_help'
require 'couchbase-orm'

CouchbaseOrm.logger = Logger.new(STDOUT)

class Post < CouchbaseOrm::Base
  n1ql :all # => emits :id and will return all comments
  attribute :title, type: String
  attribute :body, type: String
  attribute :draft, type: Boolean
end

class FirstTest < ActiveSupport::TestCase
  test 'the truth' do
    id = "newid_#{DateTime.now.strftime('%s')}"
    p = Post.new(id: id,
                 title: 'Hello world',
                 draft: true)
    p.save
    retrieved_p = Post.find(id)
    assert_equal retrieved_p.title, p.title
    retrieved_p.body = 'Once upon the times....'
    retrieved_p.save

    retrieved_p2 = Post.find(id)
    assert_equal retrieved_p2.body, retrieved_p.body
  end
end