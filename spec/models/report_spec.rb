RSpec.describe Report do
  describe "#download_redirect_url" do
    subject(:download_redirect_url) { described_class.new(resource_id: "commodities").download_redirect_url }

    let(:api_client) { instance_double(Faraday::Connection) }
    let(:response) do
      instance_double(
        Faraday::Response,
        headers: { "location" => "https://reporting.trade-tariff.service.gov.uk/uk/reporting/file.csv" },
      )
    end

    before do
      allow(described_class).to receive(:api).and_return(api_client)
      allow(api_client).to receive(:get).with("admin/reports/commodities/download").and_return(response)
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
