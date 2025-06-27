FactoryBot.define do
  factory :live_issue do
    sequence(:resource_id) { |n| n }
    sequence(:title) { 'This is a Live Issue' }
    description { 'This is a description of the issue' }
    suggested_action { 'This is a suggested action on the issue' }
    status { 'Active' }
    date_discovered { Time.zone.today }
    date_resolved { nil }
    commodities { %w[0101000000 0101000090] }
    updated_at { Time.zone.now }
  end
end
