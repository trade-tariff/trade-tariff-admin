FactoryBot.define do
  factory :quota_balance_event, class: 'QuotaOrderNumbers::QuotaBalanceEvent' do
    id { '22619-2022-01-12T11:00:00Z' }
    occurrence_timestamp { '2022-01-12T11:00:00.000Z' }
    new_balance { '18145960.0' }
    imported_amount { '35040.0' }
  end
end
