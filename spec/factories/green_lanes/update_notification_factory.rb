FactoryBot.define do
  factory :update_notification, class: 'GreenLanes::UpdateNotification' do
    sequence(:id) { |n| n }
    measure_type_id { '464' }
    regulation_id { 'R9700880' }
    regulation_role { '3' }
    measure_type_description { 'Measure Description' }
    regulation_description { 'Regulation Description' }
  end
end
