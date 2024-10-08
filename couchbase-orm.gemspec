require File.expand_path('../lib/couchbase-orm/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = 'couchbase-orm'
  gem.version = CouchbaseOrm::VERSION
  gem.license = 'Apache-2.0'
  gem.authors = ['Stephen von Takach', 'Gauthier Monserand', 'Pierre Merlin', 'Julien Burnet-Fauche']
  gem.homepage = 'https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm'
  gem.metadata = {
    "source_code_uri" => "https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm",
    "bug_tracker_uri" => "https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm/issues",
    "documentation_uri" => "https://couchbase-ruby-orm.com/",
    "homepage_uri" => "https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm"
  }
  gem.summary = 'Couchbase ORM for Rails'
  gem.description = 'A Couchbase ORM for Rails'

  gem.required_ruby_version = '>= 2.7.0'
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'activemodel', ENV['ACTIVE_MODEL_VERSION'] || '>= 5.2'

  gem.add_runtime_dependency     'couchbase',    '>= 3.4.2'
  gem.add_runtime_dependency     'radix',        '~> 2.2' # converting numbers to and from any base
  gem.add_runtime_dependency     'json-schema',  '>= 3' # validating JSON against a schema

  gem.add_development_dependency 'rake', '~> 12.2'
  gem.add_development_dependency 'rspec', '~> 3.7'
  gem.add_development_dependency 'yard', '~> 0.9'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-stack_explorer'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'actionpack'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'base64'

  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
