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
  test "the truth" do
    assert true
    puts "====> save new"
    p = Post.new(id: 'hello-world5',
                 title: 'Hello world',
                 draft: true)
    #p.save
    puts "====> get "

    p = Post.find('hello-world5')
    p.body = "Once upon the times...."
    puts "====> update "

    p.save
  end
end