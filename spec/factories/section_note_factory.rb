FactoryBot.define do
  sequence(:section_note_id) { |n| n }

  factory :section_note do
    section_id { generate(:section_id) }
    content    { "Content of note" }

    trait :persisted do
      resource_id { generate(:section_note_id) }
    end
  end
end
