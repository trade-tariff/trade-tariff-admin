source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

# Server
gem 'puma'
gem 'rails', '~> 6'

# DB
gem 'pg'

# Assets
gem 'bootstrap-datepicker-rails'
gem 'bootstrap-sass'
gem 'coffee-rails'
gem 'govuk_admin_template'
gem 'jquery-rails'
gem 'sass-rails'
gem 'uglifier'

# Markdown
gem 'addressable'
gem 'govspeak'
gem 'govuk_publishing_components'

# API
gem 'faraday_middleware'
gem 'her'
gem 'oj'

# Cache
gem 'redis'
gem 'redis-activesupport'

# Authorization / SSO
gem 'gds-sso'
gem 'plek'
gem 'pundit'

# Helpers
gem 'kaminari'
gem 'responders'
gem 'simple_form'

# File upload / mime type
gem 'marcel'
gem 'shrine'

# Logging
gem 'lograge'
gem 'logstash-event'

# Background jobs
gem 'sidekiq', '< 7'
gem 'sidekiq-scheduler', '~> 3.0'

# Misc
gem 'bootsnap', require: false
gem 'nokogiri', '>= 1.10.10'

group :development, :test do
  gem 'brakeman'
  gem 'dotenv-rails'
end

group :development do
  gem 'rubocop-govuk'
end

group :test do
  gem 'capybara'
  gem 'ci_reporter'
  gem 'ci_reporter_rspec'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'webmock'
end

group :production do
  gem 'sentry-raven'
end
