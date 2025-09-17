require "rails_helper"

RSpec.describe QuotaOrderNumbers::QuotaOrderNumberOrigin do
  subject(:quota_order_number_origin) { build(:quota_order_number_origin) }

  let(:expected_attributes) do
    {
      geographical_area_id: "5050",
      geographical_area_description: "Countries subject to UK safeguard measures",
      validity_start_date: "2021-07-01T00:00:00.000Z",
      validity_end_date: "2029-07-01T00:00:00.000Z",
    }
  end

  it "implements the correct attributes" do
    expect(quota_order_number_origin).to have_attributes(expected_attributes)
  end
end
