require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


APP_SLUG = 'trade-tariff-admin'.freeze

module TradeTariffAdmin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    require 'trade_tariff_admin'
    require 'trade_tariff_admin/service_chooser'
    require 'search_references/title_normaliser'

    config.exceptions_app = routes

    config.action_dispatch.rescue_responses.merge!(
      'Faraday::ResourceNotFound' => :not_found,
    )

    config.action_dispatch.default_headers.merge!(
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '0',
      'X-Content-Type-Options' => 'nosniff'
    )


    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.x.http.retry_options = {}
  end
end

ADAPTER = Rails.application.config.database_configuration[Rails.env].try(:[], "adapter")

if ADAPTER == 'sqlite3'
  require 'sqlite3'
else
  require 'pg'
end
