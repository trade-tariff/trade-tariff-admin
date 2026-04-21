# User Management: SUPERADMIN can create/delete users, TECHNICAL_OPERATOR can view/update users
# Exception: Basic auth allows user management regardless of role (testing mode)
# Basic auth override only works when basic auth is enabled and for non-guest users
class UserPolicy < ApplicationPolicy
  def index?
    basic_auth_override? || technical_operator?
  end

  def assign_superadmin?
    superadmin?
  end

  def create?
    basic_auth_override? || superadmin?
  end

  def show?
    basic_auth_override? || technical_operator?
  end

  def update?
    basic_auth_override? || technical_operator?
  end

  def destroy?
    basic_auth_override? || superadmin?
  end

private

  def basic_auth_override?
    return false unless TradeTariffAdmin.basic_session_authentication?
    return false if user&.guest?

    true
  end
end
