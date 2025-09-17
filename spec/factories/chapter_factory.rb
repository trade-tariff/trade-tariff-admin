FactoryBot.define do
  sequence(:chapter_description) { |n| "description #{n}" }
  sequence(:sid) { |n| n }

  factory :chapter do
    goods_nomenclature_item_id { 10.times.map { Random.rand(1..9) }.join }
    producline_suffix { 80 }
    goods_nomenclature_sid { generate(:sid) }
    description { generate(:chapter_description) }

    trait :with_note do
      chapter_note do
        attributes_for(
          :chapter_note,
          :persisted,
          chapter_id: goods_nomenclature_item_id.first(2),
        )
      end
      chapter_note_id { chapter_note[:resource_id] }
    end

    trait :with_section do
      association :section, strategy: :build

      section_id { section.try(:id) || section.try(:[], "id") }
    end
  end
end
