FactoryBot.define do
  factory :news_collection, class: "News::Collection" do
    sequence(:resource_id, &:to_s)
    sequence(:name) { |n| "Collection #{n}" }
    priority { 1 }
    published { true }
    subscribable { false }
    description { "some description" }
    slug { nil }
  end
end
