require "rails_helper"
require "gds-sso/lint/user_spec"

RSpec.describe User do
  describe "gds-sso" do
    it_behaves_like "a gds-sso user class"
  end

  describe "#hmrc_admin" do
    context "when user has hmrc admin access" do
      let!(:user) { create :user, :hmrc_admin }

      it { expect(user.hmrc_admin?).to be(true) }
    end

    context "when user does not have hmrc admin access" do
      let!(:user) { create :user }

      it { expect(user.hmrc_admin?).not_to be(true) }
    end
  end

  describe "#update" do
    let!(:user) { create :user }
    let(:attrs) do
      attributes_for :user
    end

    before do
      user.update!(attrs)
      user.reload
    end

    it "updates the user attributes", :aggregate_failures do
      expect(user.name).to eq(attrs[:name])
      expect(user.email).to eq(attrs[:email])
    end
  end

  describe "#create!" do
    describe "valid" do
      let(:attrs) do
        attributes_for :user
      end

      it {
        expect {
          described_class.create!(attrs)
        }.to change(described_class, :count).by(1)
      }
    end

    describe "invalid" do
      let!(:user) { create :user }
      let(:attrs) do
        attributes_for(:user).merge(
          id: user.id,
        )
      end

      it {
        expect {
          described_class.create!(attrs)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      }
    end
  end

  describe ".from_passwordless_payload!" do
    let(:token_payload) do
      {
        "sub" => "user-123",
        "email" => "newuser@example.com",
        "name" => "New User",
        "permissions" => %w[perm-1],
      }
    end

    it "returns nil when payload is missing required fields", :aggregate_failures do
      expect(described_class.from_passwordless_payload!(nil)).to be_nil
      expect(described_class.from_passwordless_payload!({})).to be_nil
    end

    it "creates a user with provided attributes", :aggregate_failures do
      user = described_class.from_passwordless_payload!(token_payload)

      expect(user.uid).to eq("user-123")
      expect(user.email).to eq("newuser@example.com")
      expect(user.name).to eq("New User")
      expect(user.permissions).to include(User::Permissions::SIGNIN, "perm-1")
    end

    it "updates an existing user without dropping permissions", :aggregate_failures do
      existing_user = create(:user, email: token_payload["email"], permissions: %w[existing])

      user = described_class.from_passwordless_payload!(token_payload.except("permissions"))

      expect(user.id).to eq(existing_user.id)
      expect(user.permissions).to include("existing")
    end

    it "updates the uid when it changes" do
      create(:user, email: token_payload["email"], uid: "old")

      updated = described_class.from_passwordless_payload!(token_payload)

      expect(updated.uid).to eq("user-123")
    end
  end

  describe ".dummy_user!" do
    it "creates or updates a stub user with signin permission", :aggregate_failures do
      dummy_user = described_class.dummy_user!

      expect(dummy_user.uid).to eq("dummy_user")
      expect(dummy_user.permissions).to include(User::Permissions::SIGNIN)
    end
  end

  describe "associations" do
    it "has many sessions", :aggregate_failures do
      association = described_class.reflect_on_association(:sessions)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end
end
