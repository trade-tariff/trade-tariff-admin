RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { create(:user, :guest) }
  let(:record) { instance_double(Object) }

  describe "deny-by-default behavior" do
    it "denies index by default" do
      expect(policy.index?).to be(false)
    end

    it "denies show by default" do
      expect(policy.show?).to be(false)
    end

    it "denies create by default" do
      expect(policy.create?).to be(false)
    end

    it "denies update by default" do
      expect(policy.update?).to be(false)
    end

    it "denies destroy by default" do
      expect(policy.destroy?).to be(false)
    end
  end

  describe "role helper methods" do
    context "with technical operator" do
      let(:user) { create(:user, :technical_operator) }

      it "returns true for technical_operator?" do
        expect(policy.technical_operator?).to be(true)
      end

      it "returns false for other roles", :aggregate_failures do
        expect(policy.hmrc_admin?).to be(false)
        expect(policy.auditor?).to be(false)
        expect(policy.guest?).to be(false)
      end
    end

    context "with hmrc admin" do
      let(:user) { create(:user, :hmrc_admin) }

      it "returns true for hmrc_admin?" do
        expect(policy.hmrc_admin?).to be(true)
      end
    end

    context "with auditor" do
      let(:user) { create(:user, :auditor) }

      it "returns true for auditor?" do
        expect(policy.auditor?).to be(true)
      end
    end

    context "with guest" do
      let(:user) { create(:user, :guest) }

      it "returns true for guest?" do
        expect(policy.guest?).to be(true)
      end
    end

    context "with nil user" do
      let(:user) { nil }

      it "returns false for all role checks", :aggregate_failures do
        expect(policy.technical_operator?).to be(false)
        expect(policy.hmrc_admin?).to be(false)
        expect(policy.auditor?).to be(false)
        expect(policy.guest?).to be(false)
      end
    end
  end

  describe "#can_access_xi?" do
    it "returns true for technical operator" do
      user = create(:user, :technical_operator)
      policy = described_class.new(user, record)
      expect(policy.can_access_xi?).to be(true)
    end

    it "returns true for auditor" do
      user = create(:user, :auditor)
      policy = described_class.new(user, record)
      expect(policy.can_access_xi?).to be(true)
    end

    it "returns false for hmrc admin" do
      user = create(:user, :hmrc_admin)
      policy = described_class.new(user, record)
      expect(policy.can_access_xi?).to be(false)
    end

    it "returns false for guest" do
      user = create(:user, :guest)
      policy = described_class.new(user, record)
      expect(policy.can_access_xi?).to be(false)
    end
  end
end
