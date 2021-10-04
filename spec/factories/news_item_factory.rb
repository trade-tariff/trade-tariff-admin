FactoryBot.define do
  factory :news_item do
    sequence(:id) { |n| n }
    title { "News item #{id}" }
    content { 'Lorem **ipsum**' }
    display_style { NewsItem::DISPLAY_STYLE_REGULAR }
    show_on_uk { true }
    show_on_xi { true }
    show_on_home_page { true }
    show_on_updates_page { false }
    start_date { Time.zone.yesterday }
    end_date { nil }
    created_at { 2.days.ago.to_date }
    updated_at { nil }

    trait :updates_page do
      show_on_home_page { false }
      show_on_updates_page { true }
    end

    trait :all_pages do
      show_on_home_page { true }
      show_on_updates_page { true }
    end

    trait :no_uk do
      show_on_uk { false }
    end

    trait :no_xi do
      show_on_xi { false }
    end
  end
end
