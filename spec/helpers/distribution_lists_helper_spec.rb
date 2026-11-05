RSpec.describe DistributionListsHelper, type: :helper do
  describe "#distribution_list_display_name" do
    it "removes the dl- prefix and title-cases the rest", :aggregate_failures do
      expect(helper.distribution_list_display_name("dl-green-lanes")).to eq("Green Lanes")
      expect(helper.distribution_list_display_name("dl-tariff")).to eq("Tariff")
    end

    it "keeps known acronyms in upper case", :aggregate_failures do
      expect(helper.distribution_list_display_name("dl-cds-updates")).to eq("CDS Updates")
      expect(helper.distribution_list_display_name("dl-xi-api-alerts")).to eq("XI API Alerts")
    end

    it "returns the name when nothing is left after the prefix", :aggregate_failures do
      expect(helper.distribution_list_display_name("dl-")).to eq("dl-")
      expect(helper.distribution_list_display_name(nil)).to eq("")
    end
  end

  it "labels a deletion" do
    expect(helper.distribution_list_audit_action("user_deleted")).to eq("Cognito user and email deleted")
  end

  it "formats the time in London time" do
    expect(helper.distribution_list_audit_time(Time.utc(2026, 7, 1, 9, 5, 3))).to eq("1 Jul 2026 10:05:03 BST")
  end
end
