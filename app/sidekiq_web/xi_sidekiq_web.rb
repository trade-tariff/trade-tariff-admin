require "sidekiq/web"

# Sidekiq Web for the XI backend. It reads the XI Sidekiq Redis.
# Mounted at /sidekiq/xi behind SidekiqWebConstraint.
class XiSidekiqWeb < Sidekiq::Web
  # Sidekiq::Web keeps its pool in @pool (see Sidekiq::Web.redis_pool=), so this does too.
  def self.redis_pool
    @pool ||= Sidekiq::RedisConnection.create(url: TradeTariffAdmin.sidekiq_xi_redis_url, size: 5) # rubocop:disable Naming/MemoizedInstanceVariableName
  end
end
