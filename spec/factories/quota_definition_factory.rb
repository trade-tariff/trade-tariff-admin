FactoryBot.define do
  factory :quota_definition do
    id {}
    quota_order_number_id {}
    validity_start_date {}
    validity_end_date {}
    initial_volume {}
    measurement_unit {}

    trait :with_quota_balance_events do
      quota_balance_events { [attributes_for(:quota_balance_event)] }
    end

    trait :without_quota_balance_events do
      quota_balance_events { [] }
    end
  end
end
