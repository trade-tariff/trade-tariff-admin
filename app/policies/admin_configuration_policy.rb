class AdminConfigurationPolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  def update?
    superadmin?
  end

  def create?
    false
  end

  def destroy?
    false
  end
end
