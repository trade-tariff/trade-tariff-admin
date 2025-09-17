FactoryBot.define do
  sequence(:chapter_note_id) { |n| n }

  factory :chapter_note do
    content { "Content of note" }

    trait :persisted do
      resource_id { generate(:chapter_note_id) }
    end
  end
end
