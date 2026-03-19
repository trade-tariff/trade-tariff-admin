RSpec.describe Report do
  describe "#download_redirect_url" do
    subject(:download_redirect_url) do
      described_class.new(
        resource_id: "commodities",
        download_url: "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv",
      ).download_redirect_url
    end

    it { is_expected.to eq("https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv") }
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
