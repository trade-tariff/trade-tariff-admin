# User Management: ONLY TECHNICAL_OPERATOR may manage users
# Exception: Basic auth allows user management regardless of role (testing mode)
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
    TradeTariffAdmin.basic_session_authentication?
  end
end
