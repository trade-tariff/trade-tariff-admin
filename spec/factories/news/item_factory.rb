FactoryBot.define do
  factory :news_item, class: 'News::Item' do
    sequence(:id) { |n| n }
    title { "News item #{id}" }
    slug { "news-item-#{id}" }
    precis { 'precis content' }
    content { 'Lorem **ipsum**' }
    display_style { News::Item::DISPLAY_STYLE_REGULAR }
    show_on_uk { true }
    show_on_xi { true }
    show_on_home_page { false }
    show_on_updates_page { false }
    show_on_banner { false }
    start_date { Time.zone.yesterday }
    end_date { nil }
    created_at { 2.days.ago.to_date }
    updated_at { nil }

    trait :updates_page do
      show_on_updates_page { true }
    end

    trait :home_page do
      show_on_home_page { true }
    end

    trait :banner do
      show_on_banner { true }
    end

    trait :no_uk do
      show_on_uk { false }
    end

    trait :no_xi do
      show_on_xi { false }
    end
  end
end
