FactoryBot.define do
  factory :heading do
    goods_nomenclature_item_id { 10.times.map { Random.rand(1..9) }.join }

    description { 'Live Horses, Asses, Mules And Hinnies' }

    trait :with_chapter do
      association :chapter, strategy: :build

      chapter_id { chapter.id }
    end
  end
end
