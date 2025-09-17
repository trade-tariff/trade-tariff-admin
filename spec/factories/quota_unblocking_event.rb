FactoryBot.define do
  factory :quota_unblocking_event, class: "QuotaOrderNumbers::QuotaUnblockingEvent" do
    resource_id { "123" }
    unblocking_date { "2022-11-11" }
    event_type { "Unblocking event" }
  end
end
