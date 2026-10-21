RSpec.describe DistributionListsHelper, type: :helper do
  it "labels a deletion" do
    expect(helper.distribution_list_audit_action("user_deleted")).to eq("Cognito user and email deleted")
  end

  it "formats the time in London time" do
    expect(helper.distribution_list_audit_time(Time.utc(2026, 7, 1, 9, 5, 3))).to eq("1 Jul 2026 10:05:03 BST")
  end
end
