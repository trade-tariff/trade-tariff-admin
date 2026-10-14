require "sidekiq/web"

# Sidekiq Web for the UK backend. It reads the UK Sidekiq Redis.
# Mounted at /sidekiq/uk behind SidekiqWebConstraint.
class UkSidekiqWeb < Sidekiq::Web
  def self.redis_pool
    pool
  end

  # Sidekiq::Web stores the pool in @pool.
  def self.pool
    @pool ||= Sidekiq::RedisConnection.create(url: TradeTariffAdmin.sidekiq_uk_redis_url, size: 5)
  end
  private_class_method :pool
end
