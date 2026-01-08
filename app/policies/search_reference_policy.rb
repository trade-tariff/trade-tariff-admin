# Search References: TECHNICAL_OPERATOR full control, HMRC_ADMIN create/update (no delete), AUDITOR read-only, GUEST hidden
class SearchReferencePolicy < ApplicationPolicy
  def index?
    technical_operator? || hmrc_admin? || auditor?
  end

  def show?
    technical_operator? || hmrc_admin? || auditor?
  end

  def create?
    technical_operator? || hmrc_admin?
  end

  def update?
    technical_operator? || hmrc_admin?
  end

  def destroy?
    technical_operator?
  end
end
