require "sidekiq/web"

# Sidekiq Web for the UK backend. It reads the UK Sidekiq Redis.
# Mounted at /sidekiq/uk behind SidekiqWebConstraint.
class UkSidekiqWeb < Sidekiq::Web
  # Sidekiq::Web keeps its pool in @pool (see Sidekiq::Web.redis_pool=), so this does too.
  def self.redis_pool
    @pool ||= Sidekiq::RedisConnection.create(url: TradeTariffAdmin.sidekiq_uk_redis_url, size: 5) # rubocop:disable Naming/MemoizedInstanceVariableName
  end
end
