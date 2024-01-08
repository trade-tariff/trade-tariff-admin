require 'sidekiq'
require 'trade_tariff_admin'

Sidekiq.configure_server do |config|
  config.redis = TradeTariffAdmin.redis_config
end

Sidekiq.configure_client do |config|
  config.redis = TradeTariffAdmin.redis_config
end
