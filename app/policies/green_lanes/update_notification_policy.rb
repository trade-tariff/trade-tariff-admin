# XI Service - Update Notifications: TECHNICAL_OPERATOR full control, AUDITOR read-only, HMRC_ADMIN/GUEST hidden
class GreenLanes::UpdateNotificationPolicy < ApplicationPolicy
  def index?
    can_access_xi?
  end

  def show?
    can_access_xi?
  end

  def update?
    technical_operator?
  end
end
