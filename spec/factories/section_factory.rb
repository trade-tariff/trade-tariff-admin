FactoryBot.define do
  sequence(:section_id) { |n| n }

  factory :section do
    resource_id { generate(:section_id) }
    position        { resource_id }
    numeral         { resource_id }
    title           { "Section Title" }
  end
end
