FactoryBot.define do
  factory :quota_exhaustion_event, class: "QuotaOrderNumbers::QuotaExhaustionEvent" do
    resource_id { "123" }
    exhaustion_date { "2022-11-11" }
    event_type { "Exhaustion event" }
  end
end
