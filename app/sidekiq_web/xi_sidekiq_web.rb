require "sidekiq/web"

# Sidekiq Web for the XI backend. It reads the XI Sidekiq Redis.
# Mounted at /sidekiq/xi behind SidekiqWebConstraint.
class XiSidekiqWeb < Sidekiq::Web
  def self.redis_pool
    pool
  end

  # Sidekiq::Web stores the pool in @pool.
  def self.pool
    @pool ||= Sidekiq::RedisConnection.create(url: TradeTariffAdmin.sidekiq_xi_redis_url, size: 5)
  end
  private_class_method :pool
end
