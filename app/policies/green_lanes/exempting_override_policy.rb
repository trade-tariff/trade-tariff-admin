# XI Service - Exempting Overrides: TECHNICAL_OPERATOR full control, AUDITOR read-only, HMRC_ADMIN/GUEST hidden
class GreenLanes::ExemptingOverridePolicy < ApplicationPolicy
  def index?
    can_access_xi?
  end

  def show?
    can_access_xi?
  end

  def create?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
