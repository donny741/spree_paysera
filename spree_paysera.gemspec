# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paysera'
  s.version     = '0.39'
  s.summary     = 'Spree integration with Paysera.'
  s.description = 'Spree integration with Paysera.'

  s.author    = 'Donatas Povilaitis'
  s.email     = 'ddonatasjar@gmail.com'
  s.homepage  = 'https://github.com/donny741/'

  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 3.1.0', '< 5.0'
  s.add_dependency 'spree_backend', spree_version
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_extension'
  s.add_dependency 'spree_frontend', spree_version

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot', '~> 4.7'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec-rails', '~> 4.0.0.beta2'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'webmock', '~> 2.3'
end
