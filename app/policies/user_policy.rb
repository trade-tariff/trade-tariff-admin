# User Management: ONLY TECHNICAL_OPERATOR may manage users
# Exception: Basic auth allows user management regardless of role (testing mode)
# Basic auth override only works in non-production environments and for non-guest users
class UserPolicy < ApplicationPolicy
  def index?
    basic_auth_override? || technical_operator?
  end

  def show?
    basic_auth_override? || technical_operator?
  end

  def update?
    basic_auth_override? || technical_operator?
  end

private

  def basic_auth_override?
    return false unless TradeTariffAdmin.basic_session_authentication?
    return false if Rails.env.production?
    return false if user&.guest?

    true
  end
end
