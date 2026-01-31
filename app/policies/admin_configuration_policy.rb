class AdminConfigurationPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def update?
    technical_operator?
  end

  def create?
    false
  end

  def destroy?
    false
  end
end
