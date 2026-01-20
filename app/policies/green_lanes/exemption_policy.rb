# XI Service - Exemptions: TECHNICAL_OPERATOR full control, AUDITOR read-only, HMRC_ADMIN/GUEST hidden
class GreenLanes::ExemptionPolicy < ApplicationPolicy
  def index?
    can_access_xi?
  end

  def show?
    can_access_xi?
  end

  def create?
    technical_operator?
  end

  def update?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
