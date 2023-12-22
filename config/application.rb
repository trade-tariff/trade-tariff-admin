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

    config.active_job.queue_adapter = :sidekiq

    config.exceptions_app = routes

    config.action_dispatch.rescue_responses.merge!(
      'Faraday::ResourceNotFound' => :not_found,
    )
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
