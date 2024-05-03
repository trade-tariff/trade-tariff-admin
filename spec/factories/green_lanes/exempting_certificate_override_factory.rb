FactoryBot.define do
  factory :exempting_certificate_override, class: 'GreenLanes::ExemptingCertificateOverride' do
    sequence(:id) { |n| n }
    certificate_type_code { 'Y' }
    certificate_code      { '435' }
    created_at { 2.days.ago.to_date }
    updated_at { nil }
  end
end
