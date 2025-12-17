RSpec.describe User do
  describe "role helper methods" do
    describe "#technical_operator?" do
      context "when user has technical operator role" do
        let!(:user) { create :user, :technical_operator }

        it { expect(user.technical_operator?).to be(true) }
      end

      context "when user does not have technical operator role" do
        let!(:user) { create :user }

        it { expect(user.technical_operator?).to be(false) }
      end
    end

    describe "#hmrc_admin?" do
      context "when user has hmrc admin role" do
        let!(:user) { create :user, :hmrc_admin_role }

        it { expect(user.hmrc_admin?).to be(true) }
      end

      context "when user does not have hmrc admin role" do
        let!(:user) { create :user }

        it { expect(user.hmrc_admin?).to be(false) }
      end
    end

    describe "#auditor?" do
      context "when user has auditor role" do
        let!(:user) { create :user, :auditor }

        it { expect(user.auditor?).to be(true) }
      end

      context "when user does not have auditor role" do
        let!(:user) { create :user }

        it { expect(user.auditor?).to be(false) }
      end
    end

    describe "#guest?" do
      context "when user has guest role" do
        let!(:user) { create :user, :guest }

        it { expect(user.guest?).to be(true) }
      end

      context "when user does not have guest role" do
        let!(:user) { create :user, :technical_operator }

        it { expect(user.guest?).to be(false) }
      end
    end
  end

  describe "role validation" do
    describe "single role constraint" do
      it "allows a user to have one role", :aggregate_failures do
        user = create(:user, :technical_operator)
        expect(user).to be_valid
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
      end

      it "prevents a user from having multiple roles", :aggregate_failures do
        user = create(:user, :technical_operator)
        user.add_role(User::HMRC_ADMIN)
        expect(user).not_to be_valid
        expect(user.errors[:roles]).to include("can only have one role at a time")
      end
    end

    describe "default role assignment" do
      it "assigns GUEST role by default for new users", :aggregate_failures do
        user = build(:user)
        expect(user.roles).to be_empty
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
        expect(User::VALID_ROLES).to contain_exactly(
          User::TECHNICAL_OPERATOR,
          User::HMRC_ADMIN,
          User::AUDITOR,
          User::GUEST,
        )
      end
    end

    describe "#current_role" do
      it "returns the user's current role name" do
        user = create(:user, :technical_operator)
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
      end

      it "returns nil if user has no roles" do
        user = described_class.new
        expect(user.current_role).to be_nil
      end
    end

    describe "#set_role" do
      it "removes existing role and assigns new role", :aggregate_failures do
        user = create(:user, :technical_operator)
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)

        user.set_role(User::HMRC_ADMIN)
        user.save!

        expect(user.current_role).to eq(User::HMRC_ADMIN)
        expect(user.roles.count).to eq(1)
      end

      it "replaces role when changing from one role to another", :aggregate_failures do
        user = create(:user, :hmrc_admin_role)
        expect(user.current_role).to eq(User::HMRC_ADMIN)

        user.set_role(User::AUDITOR)
        user.save!

        expect(user.current_role).to eq(User::AUDITOR)
        expect(user.roles.count).to eq(1)
      end

      it "returns false for invalid role name" do
        user = create(:user)
        result = user.set_role("INVALID_ROLE")
        expect(result).to be(false)
      end

      it "ensures user cannot have multiple roles after set_role", :aggregate_failures do
        user = create(:user, :technical_operator)
        user.set_role(User::GUEST)
        user.save!

        expect(user.roles.count).to eq(1)
        expect(user.current_role).to eq(User::GUEST)
      end
    end

    describe "ensure_single_role callback" do
      it "removes extra roles if somehow multiple exist", :aggregate_failures do
        user = create(:user, :technical_operator)
        # Manually add another role (bypassing validation)
        user.roles << Role.find_or_create_by(name: User::HMRC_ADMIN)
        expect(user.roles.count).to eq(2)

        user.save!

        expect(user.roles.count).to eq(1)
        expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
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

    it "creates a user with provided attributes", :aggregate_failures do
      user = described_class.from_passwordless_payload!(token_payload)

      expect(user.uid).to eq("user-123")
      expect(user.email).to eq("newuser@example.com")
      expect(user.name).to eq("New User")
    end

    it "preserves existing role when updating", :aggregate_failures do
      existing_user = create(:user, email: token_payload["email"])
      existing_user.remove_role(existing_user.current_role) if existing_user.current_role
      existing_user.add_role(User::TECHNICAL_OPERATOR)

      user = described_class.from_passwordless_payload!(token_payload)

      expect(user.id).to eq(existing_user.id)
      expect(user.current_role).to eq(User::TECHNICAL_OPERATOR)
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

  describe ".dummy_user!" do
    it "creates or updates a stub user", :aggregate_failures do
      dummy_user = described_class.dummy_user!

      expect(dummy_user.uid).to eq("dummy_user")
      expect(dummy_user.email).to eq("dummy@user.com")
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
