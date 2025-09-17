FactoryBot.define do
  factory :measure_pagination, class: "GreenLanes::MeasurePagination" do
    total_pages               { 10 }
    sequence(:current_page) { |n| n }
    limit_value { 20 }
  end
end
