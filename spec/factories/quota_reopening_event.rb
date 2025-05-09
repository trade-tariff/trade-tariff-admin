FactoryBot.define do
  factory :quota_reopening_event, class: 'QuotaOrderNumbers::QuotaReopeningEvent' do
    resource_id { '123' }
    reopening_date { '2022-11-11' }
    event_type { 'Reopening event' }
  end
end
