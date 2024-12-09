require_relative 'boot'

require 'rails/all'
require_relative '../lib/activesupport/basic_object'

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
  end
end
