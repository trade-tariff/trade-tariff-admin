FactoryBot.define do
  factory :news_collection, class: 'News::Collection' do
    sequence(:id, &:to_s)
    sequence(:name) { |n| "Collection #{n}" }
  end
end
