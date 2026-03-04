RSpec.describe GoodsNomenclatureSelfTextPolicy do
  subject(:policy) { described_class }

  let(:self_text) { GoodsNomenclatureSelfText.new(goods_nomenclature_sid: 12_345) }

  permissions :index?, :show?, :update? do
    it "grants access to technical operator" do
      user = create(:user, :technical_operator)
      expect(policy).to permit(user, self_text)
    end

    it "denies access to hmrc admin" do
      user = create(:user, :hmrc_admin)
      expect(policy).not_to permit(user, self_text)
    end

    it "denies access to auditor" do
      user = create(:user, :auditor)
      expect(policy).not_to permit(user, self_text)
    end

    it "denies access to guest user" do
      user = create(:user, :guest)
      expect(policy).not_to permit(user, self_text)
    end
  end
end
