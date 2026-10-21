RSpec.describe DistributionListRecipientForm do
  it "normalises the email" do
    expect(described_class.new(email: "  Jane.Doe@Example.COM ").email).to eq("jane.doe@example.com")
  end

  it "is valid with a well-formed email" do
    expect(described_class.new(email: "jane@example.com")).to be_valid
  end

  it "requires an email", :aggregate_failures do
    form = described_class.new(email: " ")

    expect(form).not_to be_valid
    expect(form.errors[:email]).to include("Enter an email address")
  end

  it "rejects a malformed email" do
    expect(described_class.new(email: "not-an-email")).not_to be_valid
  end

  it "rejects an email longer than 254 characters" do
    expect(described_class.new(email: "#{'a' * 250}@example.com")).not_to be_valid
  end
end
