class AdminConfigurationPolicy < ApplicationPolicy
  def index?
    superadmin?
  end

  def show?
    superadmin?
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
