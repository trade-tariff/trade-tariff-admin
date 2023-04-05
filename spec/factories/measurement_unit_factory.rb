FactoryBot.define do
  factory :measurement_unit, class: 'QuotaOrderNumbers::MeasurementUnit' do
    description { 'Kilogram (kg)' }
    measurement_unit_code { 'KGM' }
    measurement_unit_qualifier_code { 'kg' }
    abbreviation { 'kg' }
  end
end
