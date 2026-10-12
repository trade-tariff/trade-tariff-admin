require "rails_helper"

RSpec.describe UkSidekiqWeb do
  around do |example|
    described_class.instance_variable_set(:@pool, nil)
    example.run
  ensure
    described_class.instance_variable_set(:@pool, nil)
  end

  it "is a Sidekiq Web app" do
    expect(described_class.superclass).to eq(Sidekiq::Web)
  end

  it "creates a pool of 5 connections to the UK Sidekiq Redis", :aggregate_failures do
    pool = instance_double(ConnectionPool)
    allow(TradeTariffAdmin).to receive(:sidekiq_uk_redis_url).and_return("rediss://:secret@uk-sidekiq:6379")
    allow(Sidekiq::RedisConnection).to receive(:create).and_return(pool)

    expect(described_class.redis_pool).to be(pool)
    expect(Sidekiq::RedisConnection).to have_received(:create).with(url: "rediss://:secret@uk-sidekiq:6379", size: 5)
  end

  it "keeps the same pool after the first call", :aggregate_failures do
    allow(Sidekiq::RedisConnection).to receive(:create).and_return(instance_double(ConnectionPool))

    first_pool = described_class.redis_pool
    second_pool = described_class.redis_pool

    expect(second_pool).to be(first_pool)
    expect(Sidekiq::RedisConnection).to have_received(:create).once
  end

  it "does not change the Sidekiq::Web pool" do
    allow(Sidekiq::RedisConnection).to receive(:create).and_return(instance_double(ConnectionPool))

    described_class.redis_pool

    expect(Sidekiq::Web.instance_variable_get(:@pool)).to be_nil
  end
end
