# Comprehensive RBAC test suite
# Tests that all roles behave exactly as specified in the RBAC contract
# rubocop:disable RSpec/DescribeClass
RSpec.describe "RBAC Comprehensive Rules" do
  describe "GUEST role - deny-by-default" do
    let(:guest_user) { create(:user, :guest) }

    it "denies access to sections & chapters", :aggregate_failures do
      expect(SectionNotePolicy.new(guest_user, SectionNote.new).index?).to be(false)
      expect(ChapterNotePolicy.new(guest_user, ChapterNote.new).index?).to be(false)
    end

    it "denies access to search references" do
      expect(SearchReferencePolicy.new(guest_user, SearchReference.new).index?).to be(false)
    end

    it "denies access to news", :aggregate_failures do
      expect(News::ItemPolicy.new(guest_user, News::Item.new).index?).to be(false)
      expect(News::CollectionPolicy.new(guest_user, News::Collection.new).index?).to be(false)
    end

    it "denies access to live issues" do
      expect(LiveIssuePolicy.new(guest_user, LiveIssue.new).index?).to be(false)
    end

    it "denies access to quotas" do
      expect(QuotaPolicy.new(guest_user, Quota.new).index?).to be(false)
    end

    it "denies access to updates" do
      expect(UpdatePolicy.new(guest_user, Update.new).index?).to be(false)
    end

    it "denies access to rollbacks" do
      expect(RollbackPolicy.new(guest_user, Rollback.new).index?).to be(false)
    end

    it "denies access to XI services", :aggregate_failures do
      expect(GreenLanes::CategoryAssessmentPolicy.new(guest_user, double).index?).to be(false)
      expect(GreenLanes::ExemptionPolicy.new(guest_user, double).index?).to be(false)
      expect(GreenLanes::MeasurePolicy.new(guest_user, double).index?).to be(false)
    end

    it "denies access to labels" do
      expect(GoodsNomenclatureLabelPolicy.new(guest_user, GoodsNomenclatureLabel.new).index?).to be(false)
    end

    it "denies access to user management" do
      expect(UserPolicy.new(guest_user, User.new).index?).to be(false)
    end
  end

  describe "HMRC_ADMIN role" do
    let(:hmrc_admin) { create(:user, :hmrc_admin) }

    it "denies access to sections & chapters (hidden)", :aggregate_failures do
      expect(SectionNotePolicy.new(hmrc_admin, SectionNote.new).index?).to be(false)
      expect(ChapterNotePolicy.new(hmrc_admin, ChapterNote.new).index?).to be(false)
    end

    it "allows full access to search references", :aggregate_failures do
      expect(SearchReferencePolicy.new(hmrc_admin, SearchReference.new).index?).to be(true)
      expect(SearchReferencePolicy.new(hmrc_admin, SearchReference.new).create?).to be(true)
      expect(SearchReferencePolicy.new(hmrc_admin, SearchReference.new).destroy?).to be(true)
    end

    it "allows read and write (no delete) to news", :aggregate_failures do
      expect(News::ItemPolicy.new(hmrc_admin, News::Item.new).index?).to be(true)
      expect(News::ItemPolicy.new(hmrc_admin, News::Item.new).create?).to be(true)
      expect(News::ItemPolicy.new(hmrc_admin, News::Item.new).destroy?).to be(false)
    end

    it "allows read and write (no delete) to live issues", :aggregate_failures do
      expect(LiveIssuePolicy.new(hmrc_admin, LiveIssue.new).index?).to be(true)
      expect(LiveIssuePolicy.new(hmrc_admin, LiveIssue.new).create?).to be(true)
      expect(LiveIssuePolicy.new(hmrc_admin, LiveIssue.new).destroy?).to be(false)
    end

    it "denies access to quotas (hidden)" do
      expect(QuotaPolicy.new(hmrc_admin, Quota.new).index?).to be(false)
    end

    it "denies access to updates (hidden)" do
      expect(UpdatePolicy.new(hmrc_admin, Update.new).index?).to be(false)
    end

    it "denies access to rollbacks (hidden)" do
      expect(RollbackPolicy.new(hmrc_admin, Rollback.new).index?).to be(false)
    end

    it "denies access to XI services (hidden)", :aggregate_failures do
      expect(GreenLanes::CategoryAssessmentPolicy.new(hmrc_admin, double).index?).to be(false)
      expect(GreenLanes::ExemptionPolicy.new(hmrc_admin, double).index?).to be(false)
      expect(GreenLanes::MeasurePolicy.new(hmrc_admin, double).index?).to be(false)
    end

    it "denies access to labels (technical operator only)" do
      expect(GoodsNomenclatureLabelPolicy.new(hmrc_admin, GoodsNomenclatureLabel.new).index?).to be(false)
    end

    it "denies access to user management" do
      expect(UserPolicy.new(hmrc_admin, User.new).index?).to be(false)
    end
  end

  describe "AUDITOR role - read-only everywhere" do
    let(:auditor) { create(:user, :auditor) }

    it "allows read-only access to sections & chapters", :aggregate_failures do
      expect(SectionNotePolicy.new(auditor, SectionNote.new).index?).to be(true)
      expect(SectionNotePolicy.new(auditor, SectionNote.new).show?).to be(true)
      expect(SectionNotePolicy.new(auditor, SectionNote.new).create?).to be(false)
      expect(SectionNotePolicy.new(auditor, SectionNote.new).update?).to be(false)
      expect(SectionNotePolicy.new(auditor, SectionNote.new).destroy?).to be(false)
    end

    it "allows read-only access to search references", :aggregate_failures do
      expect(SearchReferencePolicy.new(auditor, SearchReference.new).index?).to be(true)
      expect(SearchReferencePolicy.new(auditor, SearchReference.new).show?).to be(true)
      expect(SearchReferencePolicy.new(auditor, SearchReference.new).create?).to be(false)
    end

    it "allows read-only access to news", :aggregate_failures do
      expect(News::ItemPolicy.new(auditor, News::Item.new).index?).to be(true)
      expect(News::ItemPolicy.new(auditor, News::Item.new).show?).to be(true)
      expect(News::ItemPolicy.new(auditor, News::Item.new).create?).to be(false)
    end

    it "allows read-only access to live issues", :aggregate_failures do
      expect(LiveIssuePolicy.new(auditor, LiveIssue.new).index?).to be(true)
      expect(LiveIssuePolicy.new(auditor, LiveIssue.new).show?).to be(true)
      expect(LiveIssuePolicy.new(auditor, LiveIssue.new).create?).to be(false)
    end

    it "allows search access to quotas (create is non-destructive search)", :aggregate_failures do
      expect(QuotaPolicy.new(auditor, Quota.new).index?).to be(true)
      expect(QuotaPolicy.new(auditor, Quota.new).show?).to be(true)
      expect(QuotaPolicy.new(auditor, Quota.new).create?).to be(true)
    end

    it "allows read-only access to updates", :aggregate_failures do
      expect(UpdatePolicy.new(auditor, Update.new).index?).to be(true)
      expect(UpdatePolicy.new(auditor, Update.new).show?).to be(true)
      expect(UpdatePolicy.new(auditor, Update.new).download?).to be(false)
    end

    it "allows read-only access to rollbacks", :aggregate_failures do
      expect(RollbackPolicy.new(auditor, Rollback.new).index?).to be(true)
      expect(RollbackPolicy.new(auditor, Rollback.new).show?).to be(true)
      expect(RollbackPolicy.new(auditor, Rollback.new).create?).to be(false)
    end

    it "allows read-only access to XI services", :aggregate_failures do
      expect(GreenLanes::CategoryAssessmentPolicy.new(auditor, double).index?).to be(true)
      expect(GreenLanes::CategoryAssessmentPolicy.new(auditor, double).show?).to be(true)
      expect(GreenLanes::CategoryAssessmentPolicy.new(auditor, double).create?).to be(false)
    end

    it "denies access to labels (technical operator only)" do
      expect(GoodsNomenclatureLabelPolicy.new(auditor, GoodsNomenclatureLabel.new).index?).to be(false)
    end

    it "denies access to user management" do
      expect(UserPolicy.new(auditor, User.new).index?).to be(false)
    end
  end

  describe "TECHNICAL_OPERATOR role - full access" do
    let(:technical_operator) { create(:user, :technical_operator) }

    it "allows full access to sections & chapters", :aggregate_failures do
      expect(SectionNotePolicy.new(technical_operator, SectionNote.new).index?).to be(true)
      expect(SectionNotePolicy.new(technical_operator, SectionNote.new).create?).to be(true)
      expect(SectionNotePolicy.new(technical_operator, SectionNote.new).update?).to be(true)
      expect(SectionNotePolicy.new(technical_operator, SectionNote.new).destroy?).to be(true)
    end

    it "allows full access to search references", :aggregate_failures do
      expect(SearchReferencePolicy.new(technical_operator, SearchReference.new).index?).to be(true)
      expect(SearchReferencePolicy.new(technical_operator, SearchReference.new).create?).to be(true)
      expect(SearchReferencePolicy.new(technical_operator, SearchReference.new).destroy?).to be(true)
    end

    it "allows full access to news", :aggregate_failures do
      expect(News::ItemPolicy.new(technical_operator, News::Item.new).index?).to be(true)
      expect(News::ItemPolicy.new(technical_operator, News::Item.new).create?).to be(true)
      expect(News::ItemPolicy.new(technical_operator, News::Item.new).destroy?).to be(true)
    end

    it "allows full access to live issues", :aggregate_failures do
      expect(LiveIssuePolicy.new(technical_operator, LiveIssue.new).index?).to be(true)
      expect(LiveIssuePolicy.new(technical_operator, LiveIssue.new).create?).to be(true)
      expect(LiveIssuePolicy.new(technical_operator, LiveIssue.new).destroy?).to be(true)
    end

    it "allows full access to quotas", :aggregate_failures do
      expect(QuotaPolicy.new(technical_operator, Quota.new).index?).to be(true)
      expect(QuotaPolicy.new(technical_operator, Quota.new).create?).to be(true)
      expect(QuotaPolicy.new(technical_operator, Quota.new).destroy?).to be(true)
    end

    it "allows full access to updates", :aggregate_failures do
      expect(UpdatePolicy.new(technical_operator, Update.new).index?).to be(true)
      expect(UpdatePolicy.new(technical_operator, Update.new).download?).to be(true)
      expect(UpdatePolicy.new(technical_operator, Update.new).apply_and_clear_cache?).to be(true)
    end

    it "allows full access to rollbacks", :aggregate_failures do
      expect(RollbackPolicy.new(technical_operator, Rollback.new).index?).to be(true)
      expect(RollbackPolicy.new(technical_operator, Rollback.new).create?).to be(true)
    end

    it "allows full access to XI services", :aggregate_failures do
      expect(GreenLanes::CategoryAssessmentPolicy.new(technical_operator, double).index?).to be(true)
      expect(GreenLanes::CategoryAssessmentPolicy.new(technical_operator, double).create?).to be(true)
      expect(GreenLanes::CategoryAssessmentPolicy.new(technical_operator, double).destroy?).to be(true)
    end

    it "allows full access to labels", :aggregate_failures do
      expect(GoodsNomenclatureLabelPolicy.new(technical_operator, GoodsNomenclatureLabel.new).index?).to be(true)
      expect(GoodsNomenclatureLabelPolicy.new(technical_operator, GoodsNomenclatureLabel.new).show?).to be(true)
      expect(GoodsNomenclatureLabelPolicy.new(technical_operator, GoodsNomenclatureLabel.new).update?).to be(true)
    end

    it "allows access to user management", :aggregate_failures do
      expect(UserPolicy.new(technical_operator, User.new).index?).to be(true)
      expect(UserPolicy.new(technical_operator, User.new).update?).to be(true)
    end
  end

  describe "XI Service access restriction" do
    it "only TECHNICAL_OPERATOR and AUDITOR can access XI services", :aggregate_failures do
      allowed = [create(:user, :technical_operator), create(:user, :auditor)]
      denied = [create(:user, :hmrc_admin), create(:user, :guest)]
      index = ->(user) { GreenLanes::CategoryAssessmentPolicy.new(user, double).index? }
      expect(allowed.map(&index)).to all(be(true))
      expect(denied.map(&index)).to all(be(false))
    end
  end

  describe "Basic Auth Override" do
    before do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(true)
    end

    it "allows user management for non-guest users", :aggregate_failures do
      hmrc_admin = create(:user, :hmrc_admin)
      expect(UserPolicy.new(hmrc_admin, User.new).index?).to be(true)
      expect(UserPolicy.new(hmrc_admin, User.new).update?).to be(true)
    end

    it "denies user management for guest users even with basic auth", :aggregate_failures do
      guest = create(:user, :guest)
      expect(UserPolicy.new(guest, User.new).index?).to be(false)
      expect(UserPolicy.new(guest, User.new).update?).to be(false)
    end

    it "denies user management when basic auth is not enabled", :aggregate_failures do
      allow(TradeTariffAdmin).to receive(:basic_session_authentication?).and_return(false)
      hmrc_admin = create(:user, :hmrc_admin)
      expect(UserPolicy.new(hmrc_admin, User.new).index?).to be(false)
      expect(UserPolicy.new(hmrc_admin, User.new).update?).to be(false)
    end

    it "does not bypass other policies", :aggregate_failures do
      guest = create(:user, :guest)
      expect(SectionNotePolicy.new(guest, SectionNote.new).index?).to be(false)
      expect(News::ItemPolicy.new(guest, News::Item.new).index?).to be(false)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
