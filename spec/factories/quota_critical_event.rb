FactoryBot.define do
  factory :quota_critical_event, class: "QuotaOrderNumbers::QuotaCriticalEvent" do
    resource_id { "123" }
    critical_state_change_date { "2022-11-11" }
    event_type { "Critical state change" }
    critical_state { "N" }
  end
end
