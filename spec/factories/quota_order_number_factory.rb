FactoryBot.define do
  factory :quota_order_number, class: 'QuotaOrderNumbers::QuotaOrderNumber' do
    id { '22619' }
    validity_start_date { '2022-01-01T00:00:00.000Z' }
    validity_end_date { '2022-12-31T23:59:59.000Z' }
  end
end
