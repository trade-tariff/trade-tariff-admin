ENV["RAILS_ENV"] ||= "test"

require "simplecov"
# require 'rspec/rebound'

SimpleCov.start "rails"
SimpleCov.formatters = SimpleCov::Formatter::HTMLFormatter

ENV["AUTH_STRATEGY"] ||= "passwordless"

require File.expand_path("../config/environment", __dir__)

require "rspec/rails"
require "pundit/rspec"
require "webmock/rspec"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.infer_spec_type_from_file_location!
  config.order = :random
  config.infer_base_class_for_anonymous_controllers = false
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.expose_dsl_globally = false

  config.include Rails.application.routes.url_helpers
  config.include FactoryBot::Syntax::Methods
  config.include ApiResponsesHelper
  config.include FeaturesHelper, type: :feature
  config.include_context "with authenticated user", type: :request
  config.include_context "with authenticated user", type: :feature

  config.before(:suite) do
    ENV["AUTH_STRATEGY"] = "passwordless"
    TradeTariffAdmin.instance_variable_set(:@auth_strategy, :passwordless)
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:deletion)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # NOTE: Ensure the service choice is reset after each test to prevent state leakage
  config.after do
    TradeTariffAdmin::ServiceChooser.service_choice = nil
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
