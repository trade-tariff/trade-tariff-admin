FactoryBot.define do
  factory :rollback do
    user

    jid { 10.times.map { Random.rand(1..9) }.join }
    enqueued_at { Time.zone.today.to_date }
    keep { [true, false].sample }
    date { Time.zone.today.ago(1.month).to_date }
  end
end
