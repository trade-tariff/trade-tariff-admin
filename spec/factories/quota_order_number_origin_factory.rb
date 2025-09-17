FactoryBot.define do
  factory :quota_order_number_origin, class: "QuotaOrderNumbers::QuotaOrderNumberOrigin" do
    geographical_area_id { "5050" }
    geographical_area_description { "Countries subject to UK safeguard measures" }
    validity_start_date { "2021-07-01T00:00:00.000Z" }
    validity_end_date { "2029-07-01T00:00:00.000Z" }
  end
end
