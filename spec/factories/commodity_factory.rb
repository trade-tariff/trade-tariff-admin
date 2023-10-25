FactoryBot.define do
  factory :commodity do
    id do
      referenced_id = 10.times.map { Random.rand(1..9) }.join
      productline_suffix = 2.times.map { Random.rand(1..9) }.join

      "#{referenced_id}-#{productline_suffix}"
    end
    producline_suffix { 80 }

    referenced_class { 'Commodity' }

    trait :with_heading do
      association :heading, strategy: :build

      heading_id { heading.to_param }
    end
  end
end
