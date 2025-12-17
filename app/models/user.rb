class User < ApplicationRecord
  rolify
  has_many :sessions, dependent: :destroy

  # Role constants
  TECHNICAL_OPERATOR = "TECHNICAL_OPERATOR".freeze
  HMRC_ADMIN = "HMRC_ADMIN".freeze
  AUDITOR = "AUDITOR".freeze
  GUEST = "GUEST".freeze

  # Valid roles
  VALID_ROLES = [TECHNICAL_OPERATOR, HMRC_ADMIN, AUDITOR, GUEST].freeze

  validate :single_role_only
  before_create :assign_default_role
  before_save :ensure_single_role

  class << self
    def from_passwordless_payload!(token)
      return if token.blank?

      email = token["email"].to_s.presence
      user_id = token["sub"].to_s.presence
      return if email.blank? || user_id.blank?

      user = User.find_or_initialize_by(email: email)

      return unless user.persisted?

      user.uid = user_id
      user.name = token["name"].presence || user.name || email
      user.disabled = false
      user.remotely_signed_out = false
      # Ensure default role is assigned if user has no roles
      user.send(:assign_default_role) if user.roles.empty?
      user.save!

      user
    end

    def dummy_user!
      User.find_or_initialize_by(uid: "dummy_user", email: "dummy@user.com").tap do |user|
        user.name = "Dummy User"
        user.disabled = false
        user.remotely_signed_out = false
        user.send(:assign_default_role) if user.roles.empty?
        user.save!
      end
    end

    def basic_auth_user!
      User.find_or_initialize_by(uid: "basic_auth_user", email: "basic_auth@trade-tariff-admin.local").tap do |user|
        user.name = "basic_auth_user"
        user.disabled = false
        user.remotely_signed_out = false
        user.send(:assign_default_role) if user.roles.empty?
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

  # Legacy permission methods
  def gds_editor?
    technical_operator?
  end

  def hmrc_editor?
    technical_operator?
  end

  def current_role
    roles.first&.name
  end

  # Virtual attribute for form handling
  def role
    current_role
  end

  def role=(role_name)
    return unless role_name.present?

    unless VALID_ROLES.include?(role_name)
      errors.add(:role, "is not a valid role")
      return
    end

    set_role(role_name)
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
    first_role = roles.first
    roles_to_remove = roles[1..]
    roles_to_remove.each { |role| remove_role(role.name) }
  end

  def assign_default_role
    return if roles.any?

    add_role(GUEST)
  end
end
