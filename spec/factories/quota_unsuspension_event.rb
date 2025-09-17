FactoryBot.define do
  factory :quota_unsuspension_event, class: "QuotaOrderNumbers::QuotaUnsuspensionEvent" do
    resource_id { "123" }
    unsuspension_date { "2022-11-11" }
    event_type { "Unsuspension event" }
  end
end
