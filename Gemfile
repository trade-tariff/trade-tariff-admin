source "https://rubygems.org"

ruby file: ".ruby-version"

# Server
gem "puma"
gem "rails", "~> 8.1"

gem "routing-filter", github: "trade-tariff/routing-filter"

# DB
gem "pg", require: false

# Assets
gem "cssbundling-rails"
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails"

# GovUK
gem "govuk-components", "6.4.0"
gem "govuk_design_system_formbuilder"

# Markdown
gem "govspeak"

# API
gem "faraday"
gem "faraday-net_http_persistent"
gem "faraday-retry"
gem "jwt"

# Authorization
gem "pundit"

# Helpers
gem "kaminari"
gem "responders"

# Logging
gem "lograge"
gem "logstash-event"

# Misc
gem "bootsnap", require: false
gem "csv", "~> 3.3"
gem "nokogiri"
gem "rubyzip"

group :development, :test do
  gem "brakeman"
  gem "dotenv-rails"
  gem "pry-rails"
end

group :development do
  gem "amazing_print"
  gem "rubocop-govuk"
  gem "ruby-lsp-rails"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "debride", "~> 1.15", require: false
  gem "factory_bot_rails"
  gem "parallel_tests"
  gem "rails-controller-testing"
  gem "rspec_junit_formatter"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "webmock"
end
