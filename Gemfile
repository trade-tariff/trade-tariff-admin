source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

# Server
gem 'puma'
gem 'rails', '~> 8.0.2'

# Custom gems we've forked
gem 'faraday_middleware' # Required for backwards compatibility with her which is abandonware
gem 'her', github: 'trade-tariff/her', branch: 'BAU-rails-8-her'
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

group :development, :test do
  gem 'brakeman'
  gem 'dotenv-rails'
  gem 'pry-rails'
end

group :development do
  gem 'amazing_print'
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
