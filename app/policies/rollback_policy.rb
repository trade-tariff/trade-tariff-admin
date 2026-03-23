# Rollback: SUPERADMIN execute/download/recover, AUDITOR index (history only), HMRC_ADMIN hidden, GUEST hidden
class RollbackPolicy < ApplicationPolicy
  def index?
    superadmin? || auditor?
  end

  def show?
    superadmin? || auditor?
  end

  def create?
    superadmin?
  end
end
