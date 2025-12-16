RSpec.describe "quotas/search" do
  subject { render && rendered }

  before do
    assign :current_quota_definition, quota_definition
    assign :quota_definitions, []
  end

  context "with quota order number origins" do
    let(:quota_definition) do
      build(
        :quota_definition,
        :with_quota_order_number,
        :with_quota_balance_events,
        :with_quota_order_number_origins,
      )
    end

    it { is_expected.to have_css "h1", text: /Quota 051822 - definitions/ }

    it { is_expected.to have_css "h2", text: "Core quota data" }

    it { is_expected.to have_css "div.govuk-accordion" }
  end
end
