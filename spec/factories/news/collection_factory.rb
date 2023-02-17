FactoryBot.define do
  factory :news_collection, class: 'News::Collection' do
    sequence(:id, &:to_s)
    sequence(:name) { |n| "Collection #{n}" }
    priority { 1 }
    published { true }
    description { 'some description' }
    slug { nil }
  end
end
