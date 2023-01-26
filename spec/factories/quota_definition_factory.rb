FactoryBot.define do
  factory :quota_definition, class: 'QuotaOrderNumbers::QuotaDefinition' do
    id { '22619' }
    quota_order_number_id { '051822' }
    validity_start_date { '2022-01-01T00:00:00.000Z' }
    validity_end_date { '2022-12-31T23:59:59.000Z' }
    initial_volume { '18181000.0' }
    measurement_unit { 'Kilogram (kg)' }
    quota_type { 'First Come First Served' }
    critical_state { 'N' }
    critical_threshold { '90' }

    trait :with_quota_order_number do
      quota_order_number { build(:quota_order_number) }
    end

    trait :without_quota_order_number do
      quota_order_number {}
    end

    trait :with_quota_balance_events do
      quota_balance_events { [build(:quota_balance_event)] }
    end

    trait :without_quota_balance_events do
      quota_balance_events { [] }
    end

    trait :with_quota_order_number_origins do
      quota_order_number_origins { [build(:quota_order_number_origin)] }
    end

    trait :without_quota_order_number_origins do
      quota_order_number_origins { [] }
    end

    trait :with_quota_unsuspension_events do
      quota_unsuspension_events { [build(:quota_unsuspension_event)] }
    end

    trait :without_quota_unsuspension_events do
      quota_unsuspension_events { [] }
    end

    trait :with_quota_exhaustion_events do
      quota_exhaustion_events { [build(:quota_exhaustion_event)] }
    end

    trait :without_quota_exhaustion_events do
      quota_exhaustion_events { [] }
    end

    trait :with_quota_reopening_events do
      quota_reopening_events { [build(:quota_reopening_event)] }
    end

    trait :without_quota_reopening_events do
      quota_reopening_events { [] }
    end

    trait :with_quota_unblocking_events do
      quota_unblocking_events { [build(:quota_unblocking_event)] }
    end

    trait :without_quota_unblocking_events do
      quota_unblocking_events { [] }
    end

    trait :with_quota_critical_events do
      quota_critical_events { [build(:quota_critical_event)] }
    end

    trait :without_quota_critical_events do
      quota_critical_events { [] }
    end
  end
end
