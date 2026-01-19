# Quotas: TECHNICAL_OPERATOR full control, HMRC_ADMIN hidden, AUDITOR search access (create is non-destructive), GUEST hidden
class QuotaPolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  def create?
    technical_operator? || auditor?
  end

  def update?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end

  def search?
    technical_operator? || auditor?
  end
end
