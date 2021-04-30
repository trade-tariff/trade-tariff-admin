source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

# Server
gem 'puma', '~> 5.0.4'
gem 'rails', '>= 6.0.3.4'
gem 'sinatra', '~> 2.0.8', require: nil

# DB
gem 'pg', '~> 1.1.3'

# Assets
gem 'bootstrap-datepicker-rails'
gem 'bootstrap-sass', '>= 3.4.1'
gem 'coffee-rails', '~> 5.0'
gem 'govuk_admin_template', '6.7.0'
gem 'jquery-rails', '~> 4.3.4'
gem 'sass-rails'
gem 'uglifier', '~> 2.7'

# Markdown
gem 'addressable', '~> 2.7'
gem 'govspeak', '6.5.6'
gem 'govuk_publishing_components', '21.5.0'

# API
gem 'faraday_middleware'
gem 'her', '1.1.0'
gem 'oj'

# Cache
gem 'redis', '~> 4.2'
gem 'redis-activesupport'

# Authorization / SSO
gem 'gds-sso', '~> 15'
gem 'plek', '~> 2.1.0'
gem 'pundit', '0.3.0'

# Helpers
gem 'kaminari', '~> 1.2'
gem 'responders'
gem 'simple_form', '>= 5.0.0'

# File upload / mime type
gem 'marcel'
gem 'shrine', '~> 3.3'

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
  gem 'brakeman', require: false
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
