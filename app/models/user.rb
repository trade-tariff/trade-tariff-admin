class User < ApplicationRecord
  rolify
  has_many :sessions, dependent: :destroy

  TECHNICAL_OPERATOR = "TECHNICAL_OPERATOR".freeze
  HMRC_ADMIN = "HMRC_ADMIN".freeze
  AUDITOR = "AUDITOR".freeze
  GUEST = "GUEST".freeze

  VALID_ROLES = [TECHNICAL_OPERATOR, HMRC_ADMIN, AUDITOR, GUEST].freeze

  validate :single_role_only
  before_create :ensure_default_role
  before_save :ensure_single_role

  class << self
    def from_passwordless_payload!(token)
      return if token.blank?

      email = token["email"].to_s.presence
      user_id = token["sub"].to_s.presence
      return if email.blank? || user_id.blank?

      user = find_by(email: email)
      return unless user

      user.assign_attributes(
        uid: user_id,
        name: token["name"].presence || user.name || email,
        disabled: false,
        remotely_signed_out: false,
      )
      user.ensure_default_role
      user.save!

      user
    end

    def basic_auth_user!
      system_user!(uid: "basic_auth_user", email: "basic_auth@trade-tariff-admin.local", name: "basic_auth_user")
    end

  private

    def system_user!(uid:, email:, name:)
      find_or_initialize_by(uid:, email:).tap do |user|
        user.name = name
        user.disabled = false
        user.remotely_signed_out = false
        user.ensure_default_role
        user.save!
      end
    end
  end

  # Role helper methods - assume single role exclusivity
  def technical_operator?
    current_role == TECHNICAL_OPERATOR
  end

  def hmrc_admin?
    current_role == HMRC_ADMIN
  end

  def auditor?
    current_role == AUDITOR
  end

  def guest?
    current_role == GUEST
  end

  def current_role
    roles.first&.name
  end

  # Virtual attribute for form handling
  def role
    current_role
  end

  def role=(role_name)
    return if role_name.blank?

    unless VALID_ROLES.include?(role_name)
      errors.add(:role, "is not a valid role")
      return
    end

    set_role(role_name)
  end

  def ensure_default_role
    return if roles.any?

    add_role(GUEST)
  end

  # Safely assign a role by removing existing roles first
  # This ensures single role constraint is maintained
  def set_role(role_name)
    return false unless VALID_ROLES.include?(role_name)

    # Remove all existing roles
    roles.each { |role| remove_role(role.name) }

    # Assign the new role
    add_role(role_name)
    true
  end

  def to_s
    name
  end

private

  def single_role_only
    return if roles.size <= 1

    errors.add(:roles, "can only have one role at a time")
  end

  def ensure_single_role
    # If somehow multiple roles exist, keep only the first one
    return if roles.size <= 1

    # Keep the first role, remove the rest
    roles_to_remove = roles[1..]
    roles_to_remove.each { |role| remove_role(role.name) }
  end
end
