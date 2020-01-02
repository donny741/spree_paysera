# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

begin
  require File.expand_path('dummy/config/environment', __dir__)
rescue LoadError
  puts 'Could not load dummy application. Please ensure you have run `bundle exec rake test_app`'
  exit
end

require 'rspec/rails'
require 'database_cleaner'
require 'ffaker'
require 'factory_bot'

# Requires factories and other useful helpers defined in spree_core.
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/factories'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/order_walkthrough'

require 'pry'

require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Domain', 'app/domain'
  add_group 'Models', 'app/models'
  add_group 'Libraries', 'app/lib'
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::TestingSupport::UrlHelpers

  # == Requests support
  #
  # Adds convenient methods to request Spree's controllers
  # spree_get :index
  config.include Spree::TestingSupport::ControllerRequests, type: :controller

  config.mock_with :rspec
  config.color = true

  # Ensure Suite is set to use transactions for speed.
  config.before :suite do
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before :each do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  # After each spec clean the database.
  config.after :each do
    DatabaseCleaner.clean
  end

  config.fail_fast = ENV['FAIL_FAST'] || false
  config.order = 'random'
end
