class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  TECHNICAL_OPERATOR = "TECHNICAL_OPERATOR".freeze
  HMRC_ADMIN = "HMRC_ADMIN".freeze
  AUDITOR = "AUDITOR".freeze
  GUEST = "GUEST".freeze

  VALID_ROLES = [TECHNICAL_OPERATOR, HMRC_ADMIN, AUDITOR, GUEST].freeze

  validates :role, inclusion: { in: VALID_ROLES }
  before_validation :ensure_default_role

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
      user.role ||= GUEST
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
        user.role ||= GUEST
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
    role
  end

  def to_s
    name
  end

private

  def ensure_default_role
    self.role = GUEST if role.blank?
  end
end
