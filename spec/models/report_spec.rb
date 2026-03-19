RSpec.describe Report do
  describe "#download_url" do
    subject(:download_url) { described_class.new(resource_id: "commodities").download_url }

    before do
      allow(TradeTariffAdmin::ServiceChooser).to receive(:api_host).and_return("https://backend.example/uk")
    end

    it { is_expected.to eq("https://backend.example/uk/admin/reports/commodities/download") }
  end

  describe "#available?" do
    subject(:report) { described_class.new(available: true) }

    it { expect(report).to be_available }
  end

  describe "#dependencies_missing?" do
    subject(:report) { described_class.new(dependencies_missing: true) }

    it { expect(report).to be_dependencies_missing }
  end
end
