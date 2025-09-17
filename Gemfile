source "https://rubygems.org"

ruby File.read(".ruby-version").chomp

# Server
gem "puma"
gem "rails", "~> 8"

gem "routing-filter", github: "trade-tariff/routing-filter"

# DB
gem "pg", require: false
gem "sqlite3", require: false

# Assets
gem "webpacker"

# GovUK
gem "govuk_design_system_formbuilder"

# Markdown
gem "addressable"
gem "govspeak"
gem "govuk-components"
gem "govuk_publishing_components"

# API
gem "faraday"
gem "faraday-net_http_persistent"
gem "faraday-retry"
gem "net-http-persistent"

# Authorization / SSO
gem "gds-sso"
gem "plek"
gem "pundit"

# Helpers
gem "kaminari"
gem "responders"

# Logging
gem "lograge"
gem "logstash-event"

# Misc
gem "bootsnap", require: false
gem "nokogiri", ">= 1.10.10"
gem "sentry-rails"

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
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "rspec_junit_formatter"
  gem "rspec-rails"
  gem "rspec-rebound"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "webmock"
end
