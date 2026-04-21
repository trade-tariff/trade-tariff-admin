# Rollback: SUPERADMIN execute/download/recover, TECHNICAL_OPERATOR/AUDITOR history access, HMRC_ADMIN hidden, GUEST hidden
class RollbackPolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  def create?
    superadmin?
  end
end
