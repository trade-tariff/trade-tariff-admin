class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  SUPERADMIN = "SUPERADMIN".freeze
  TECHNICAL_OPERATOR = "TECHNICAL_OPERATOR".freeze
  HMRC_ADMIN = "HMRC_ADMIN".freeze
  AUDITOR = "AUDITOR".freeze
  GUEST = "GUEST".freeze

  BASIC_AUTH_UID = "basic_auth_user".freeze
  BASIC_AUTH_EMAIL = "basic_auth@trade-tariff-admin.local".freeze
  BASIC_AUTH_NAME = "basic_auth_user".freeze

  ROLE_ASSIGNMENT_ORDER = [SUPERADMIN, TECHNICAL_OPERATOR, HMRC_ADMIN, AUDITOR, GUEST].freeze
  PRIVILEGED_OPERATOR_ROLES = [SUPERADMIN, TECHNICAL_OPERATOR].freeze
  VALID_ROLES = ROLE_ASSIGNMENT_ORDER

  validates :role, inclusion: { in: VALID_ROLES }
  validates :name, presence: true
  validates :email, presence: true, on: :create
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, on: :create
  validates :email, uniqueness: true, on: :create
  before_validation :normalize_email
  before_validation :ensure_default_role

  class << self
    def role_assignment_index(role)
      ROLE_ASSIGNMENT_ORDER.index(role.to_s)
    end

    def from_passwordless_payload!(token)
      return if token.blank?

      email = token["email"].to_s.downcase.presence
      user_id = token["sub"].to_s.presence
      return if email.blank? || user_id.blank?

      user = where("LOWER(email) = ?", email).first
      return unless user

      user.assign_attributes(
        uid: user_id,
        name: token["name"].presence || user.name || email,
        disabled: false,
        remotely_signed_out: false,
      )
      user.role ||= GUEST
      user.save!

      user
    end

    def basic_auth_user!
      user = find_or_initialize_by(uid: BASIC_AUTH_UID, email: BASIC_AUTH_EMAIL)
      if user.new_record?
        user.name = BASIC_AUTH_NAME
        user.disabled = false
        user.remotely_signed_out = false
      end
      user.name ||= BASIC_AUTH_NAME
      user.role = SUPERADMIN
      user.save!
      user
    end
  end

  # Role helper methods - assume single role exclusivity
  def technical_operator?
    PRIVILEGED_OPERATOR_ROLES.include?(current_role)
  end

  def superadmin?
    current_role == SUPERADMIN
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

  def basic_auth_user?
    uid == BASIC_AUTH_UID && email == BASIC_AUTH_EMAIL
  end

  def current_role
    role
  end

  def to_s
    name
  end

private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def ensure_default_role
    self.role = GUEST if role.blank?
  end
end
