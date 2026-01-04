RSpec.describe User do
  describe "#technical_operator?" do
    subject(:user) { create(:user, *traits) }

    context "when user has technical operator role" do
      let(:traits) { [:technical_operator] }

      it { is_expected.to be_technical_operator }
    end

    context "when user does not have technical operator role" do
      let(:traits) { [] }

      it { is_expected.not_to be_technical_operator }
    end
  end

  describe "#hmrc_admin?" do
    subject(:user) { create(:user, *traits) }

    context "when user has hmrc admin role" do
      let(:traits) { [:hmrc_admin] }

      it { is_expected.to be_hmrc_admin }
    end

    context "when user does not have hmrc admin role" do
      let(:traits) { [] }

      it { is_expected.not_to be_hmrc_admin }
    end
  end

  describe "#auditor?" do
    subject(:user) { create(:user, *traits) }

    context "when user has auditor role" do
      let(:traits) { [:auditor] }

      it { is_expected.to be_auditor }
    end

    context "when user does not have auditor role" do
      let(:traits) { [] }

      it { is_expected.not_to be_auditor }
    end
  end

  describe "#guest?" do
    subject(:user) { create(:user, *traits) }

    context "when user has guest role" do
      let(:traits) { [:guest] }

      it { is_expected.to be_guest }
    end

    context "when user does not have guest role" do
      let(:traits) { [:technical_operator] }

      it { is_expected.not_to be_guest }
    end
  end

  describe "role validation" do
    describe "role assignment" do
      it "allows a user to have a valid role", :aggregate_failures do
        user = create(:user, :technical_operator)
        expect(user).to be_valid
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
      end

      it "validates role inclusion", :aggregate_failures do
        user = build(:user, role: "INVALID_ROLE")
        expect(user).not_to be_valid
        expect(user.errors[:role]).to be_present
      end
    end

    describe "default role assignment" do
      it "assigns GUEST role by default when creating a new user", :aggregate_failures do
        user = create(:user)
        expect(user.current_role).to eq(User::GUEST)
        expect(user.guest?).to be(true)
      end

      it "assigns GUEST role by default for new users without a role", :aggregate_failures do
        user = build(:user, role: nil)
        user.save!
        expect(user.current_role).to eq(User::GUEST)
      end

      it "does not override existing roles", :aggregate_failures do
        user = create(:user, :technical_operator)
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
        user.reload
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
      end
    end

    describe "role constants" do
      it "defines all required role constants", :aggregate_failures do
        expect(User::TECHNICAL_OPERATOR).to eq("TECHNICAL_OPERATOR")
        expect(User::HMRC_ADMIN).to eq("HMRC_ADMIN")
        expect(User::AUDITOR).to eq("AUDITOR")
        expect(User::GUEST).to eq("GUEST")
      end

      it "includes all roles in VALID_ROLES" do
        expect(User::VALID_ROLES).to contain_exactly(User::TECHNICAL_OPERATOR, User::HMRC_ADMIN, User::AUDITOR, User::GUEST)
      end
    end

    describe "#current_role" do
      it "returns the user's current role name" do
        user = create(:user, :technical_operator)
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
      end

      it "returns the role value" do
        user = described_class.new(role: User::GUEST)
        expect(user.current_role).to eq(User::GUEST)
      end
    end

    describe "role updates" do
      it "allows changing role", :aggregate_failures do
        user = create(:user, :technical_operator)
        user.role = User::HMRC_ADMIN
        user.save!
        expect(user.current_role).to eq(User::HMRC_ADMIN)
      end

      it "replaces role when changing from one role to another", :aggregate_failures do
        user = create(:user, :hmrc_admin)
        user.role = User::AUDITOR
        user.save!
        expect(user.current_role).to eq(User::AUDITOR)
      end
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
      }
    end

    it "returns nil when payload is missing required fields", :aggregate_failures do
      expect(described_class.from_passwordless_payload!(nil)).to be_nil
      expect(described_class.from_passwordless_payload!({})).to be_nil
    end

    it "updates an existing user with provided attributes", :aggregate_failures do
      existing_user = create(:user, email: token_payload["email"])
      user = described_class.from_passwordless_payload!(token_payload)
      expect(user).to eq(existing_user)
      expect(user).to have_attributes(uid: "user-123", email: "newuser@example.com", name: "New User")
    end

    it "preserves existing role when updating", :aggregate_failures do
      existing_user = create(:user, :technical_operator, email: token_payload["email"])
      user = described_class.from_passwordless_payload!(token_payload)
      expect(user).to have_attributes(id: existing_user.id, current_role: User::TECHNICAL_OPERATOR)
    end

    it "updates the uid when it changes" do
      create(:user, email: token_payload["email"], uid: "old")

      updated = described_class.from_passwordless_payload!(token_payload)

      expect(updated.uid).to eq("user-123")
    end

    context "when the user does not exist" do
      it "does not create a user" do
        expect { described_class.from_passwordless_payload!(token_payload) }
          .not_to change(described_class, :count)
      end
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
