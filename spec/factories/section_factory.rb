FactoryBot.define do
  sequence(:section_id) { |n| n }

  factory :section do
    resource_id { generate(:section_id) }
    section_note_id { nil }
    position        { resource_id }
    numeral         { resource_id }
    title           { 'Section Title' }

    trait :with_note do
      section_note do
        attributes_for(
          :section_note,
          :persisted,
          section_id: resource_id,
        )
      end
      section_note_id { generate(:section_note_id) }
    end
  end
end
