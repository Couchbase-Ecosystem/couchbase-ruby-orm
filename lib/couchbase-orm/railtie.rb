# encoding: utf-8
#
# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2012 Couchbase, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'yaml'
require 'couchbase-orm/base'

module Rails #:nodoc:
    module Couchbase #:nodoc:
        class Railtie < Rails::Railtie #:nodoc:

            config.couchbase_orm = ActiveSupport::OrderedOptions.new
            config.couchbase_orm.ensure_design_documents = true

            # Maping of rescued exceptions to HTTP responses
            #
            # @example
            #   railtie.rescue_responses
            #
            # @return [Hash] rescued responses
            def self.rescue_responses
                {
                }
            end

            config.send(:app_generators).orm :couchbase_orm, :migration => false

            if config.action_dispatch.rescue_responses
                config.action_dispatch.rescue_responses.merge!(rescue_responses)
            end

            initializer 'couchbase_orm.setup_connection_config' do
                CouchbaseOrm::Connection.config = Rails.application.config_for(:couchbase)
            end

            # After initialization we will warn the user if we can't find a couchbase.yml and
            # alert to create one.
            initializer 'couchbase.warn_configuration_missing' do
                unless ARGV.include?('couchbase:config')
                    config.after_initialize do
                        unless Rails.root.join('config', 'couchbase.yml').file?
                            puts "\nCouchbase config not found. Create a config file at: config/couchbase.yml"
                            puts "to generate one run: rails generate couchbase:config\n\n"
                        end
                    end
                end
            end

            # Set the proper error types for Rails. NotFound errors should be
            # 404s and not 500s, validation errors are 422s.
            initializer 'couchbase.load_http_errors' do |app|
                config.after_initialize do
                    unless config.action_dispatch.rescue_responses
                        ActionDispatch::ShowExceptions.rescue_responses.update(Railtie.rescue_responses)
                    end
                end
            end

            # Check (and upgrade if needed) all design documents
            config.after_initialize do |app|
                if config.couchbase_orm.ensure_design_documents
                    begin
                        ::CouchbaseOrm::Base.descendants.each do |model|
                            model.ensure_design_document!
                        end
                    rescue ::MTLibcouchbase::Error::Timedout, ::MTLibcouchbase::Error::ConnectError, ::MTLibcouchbase::Error::NetworkError
                        # skip connection errors for now
                    end
                end
            end
        end
    end
end
