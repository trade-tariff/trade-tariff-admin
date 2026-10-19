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

  describe "#backfill_difference" do
    let(:api_client) { instance_double(Faraday::Connection) }

    before do
      allow(described_class).to receive(:api).and_return(api_client)
      allow(api_client).to receive(:post).with("admin/reports/differences/backfill")
      described_class.new(resource_id: "differences").backfill_difference
    end

    it { expect(api_client).to have_received(:post).with("admin/reports/differences/backfill") }
  end

  describe "#send_email" do
    let(:api_client) { instance_double(Faraday::Connection) }

    before do
      allow(described_class).to receive(:api).and_return(api_client)
      allow(api_client).to receive(:post).with("admin/reports/differences/send_email")
      described_class.new(resource_id: "differences").send_email
    end

    it { expect(api_client).to have_received(:post).with("admin/reports/differences/send_email") }
  end

  describe "#available?" do
    subject(:report) { described_class.new(available: true) }

    it { expect(report).to be_available }
  end

  describe "#dependencies_missing?" do
    subject(:report) { described_class.new(dependencies_missing: true) }

    it { expect(report).to be_dependencies_missing }
  end

  describe "#supports_generate?" do
    subject(:report) { described_class.new(supports_email:, supports_generate:) }

    context "when supports_generate is true" do
      let(:supports_email) { true }
      let(:supports_generate) { true }

      it { expect(report).to be_supports_generate }
    end

    context "when supports_generate is false" do
      let(:supports_email) { true }
      let(:supports_generate) { false }

      it { expect(report).not_to be_supports_generate }
    end

    context "when supports_generate is missing and the report supports email" do
      let(:supports_email) { true }
      let(:supports_generate) { nil }

      it { expect(report).not_to be_supports_generate }
    end

    context "when supports_generate is missing and the report does not support email" do
      let(:supports_email) { false }
      let(:supports_generate) { nil }

      it { expect(report).to be_supports_generate }
    end
  end
end
