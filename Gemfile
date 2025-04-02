source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

# Server
gem 'puma'
gem 'rails', '~> 7.1.2'

gem 'routing-filter', github: 'trade-tariff/routing-filter'

# DB
gem 'pg'

# Assets
gem 'webpacker'

# GovUK
gem 'govuk-components'
gem 'govuk_design_system_formbuilder'

# Markdown
gem 'addressable'
gem 'govspeak'
gem 'govuk_publishing_components'

# API
gem 'faraday_middleware'
gem 'her'

# Authorization / SSO
gem 'gds-sso'
gem 'plek'
gem 'pundit'

# Helpers
gem 'kaminari'
gem 'responders'
gem 'simple_form'

# Logging
gem 'lograge'
gem 'logstash-event'

# Misc
gem 'bootsnap', require: false
gem 'nokogiri', '>= 1.10.10'
gem 'sentry-rails'

group :development, :test do
  gem 'brakeman'
  gem 'dotenv-rails'
  gem 'pry-byebug'
  gem 'pry-rails'
end

group :development do
  gem 'awesome_print'
  gem 'rubocop-govuk'
  gem 'ruby-lsp-rails'
  gem 'ruby-lsp-rspec'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rspec-rebound'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'webmock'
end
