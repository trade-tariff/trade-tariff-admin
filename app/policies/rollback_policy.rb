# Rollback: TECHNICAL_OPERATOR execute/download/recover, HMRC_ADMIN hidden, AUDITOR index (history only), GUEST hidden
class RollbackPolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  def create?
    technical_operator?
  end
end
