# User Management: SUPERADMIN can create/delete users, TECHNICAL_OPERATOR can view/update users
# Exception: Basic auth allows user management through the synthetic SUPERADMIN user
class UserPolicy < ApplicationPolicy
  def index?
    basic_auth_override? || technical_operator?
  end

  def assignable_roles
    return [] unless role_management_access?
    return User::VALID_ROLES if superadmin?

    User::VALID_ROLES.select { |role| role_at_or_below_ceiling?(role) }
  end

  def role_option_enabled?(role)
    return false unless role_management_access?
    return false if locked_higher_role?

    assignable_roles.include?(role.to_s)
  end

  def role_submittable?(role)
    requested_role = role.to_s

    return false unless role_management_access?
    return false unless User::VALID_ROLES.include?(requested_role)
    return true if superadmin?
    return true if locked_higher_role? && unchanged_role?(requested_role)
    return false if locked_higher_role?

    assignable_roles.include?(requested_role)
  end

  def locked_higher_role?
    return false unless record.respond_to?(:current_role)
    return false unless record.persisted?
    return false if superadmin?

    higher_than_ceiling?(record.current_role)
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

  def unchanged_role?(role)
    record.respond_to?(:current_role) && record.current_role == role
  end

  def role_management_access?
    basic_auth_override? || technical_operator?
  end

  def current_user_role_index
    @current_user_role_index ||= User.role_assignment_index(user&.current_role)
  end

  def role_at_or_below_ceiling?(role)
    role_index = User.role_assignment_index(role)

    current_user_role_index.present? && role_index.present? && role_index >= current_user_role_index
  end

  def higher_than_ceiling?(role)
    role_index = User.role_assignment_index(role)

    current_user_role_index.present? && role_index.present? && role_index < current_user_role_index
  end

  def basic_auth_override?
    return false unless TradeTariffAdmin.basic_session_authentication?
    return false unless user&.basic_auth_user?

    superadmin?
  end
end
