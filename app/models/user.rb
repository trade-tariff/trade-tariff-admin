class User < ApplicationRecord
  include GDS::SSO::User

  serialize :permissions
  has_many :sessions, dependent: :destroy

  module Permissions
    SIGNIN = "signin".freeze
    HMRC_EDITOR = "HMRC Editor".freeze
    GDS_EDITOR = "GDS Editor".freeze
    HMRC_ADMIN = "HMRC Admin".freeze
  end

  class << self
    def from_passwordless_payload!(token)
      return if token.blank?

      email = token["email"].to_s.presence
      user_id = token["sub"].to_s.presence
      return if email.blank? || user_id.blank?

      user = User.find_or_initialize_by(email: email)
      user.uid = user_id
      user.name = token["name"].presence || user.name || email
      user.disabled = false
      user.remotely_signed_out = false
      user.permissions = resolve_permissions(token, user.permissions)
      user.save!

      user
    end

    def dummy_user!
      User.find_or_initialize_by(uid: "dummy_user", email: "dummy@user.com").tap do |user|
        user.name = "Dummy User"
        user.disabled = false
        user.remotely_signed_out = false
        user.permissions = Array(user.permissions).presence || [Permissions::SIGNIN]
        user.save!
      end
    end

  private

    def resolve_permissions(token, existing_permissions)
      incoming_permissions = token_permissions(token)
      permissions = incoming_permissions.presence || existing_permissions || []

      (permissions | [Permissions::SIGNIN]).reject(&:blank?)
    end

    def token_permissions(token)
      raw_permissions = token["permissions"] || token["custom:permissions"]
      raw_permissions = raw_permissions.split(",") if raw_permissions.is_a?(String)

      Array(raw_permissions).map(&:to_s)
    end
  end

  def gds_editor?
    has_permission?(Permissions::GDS_EDITOR)
  end

  def hmrc_editor?
    has_permission?(Permissions::HMRC_EDITOR)
  end

  def hmrc_admin?
    has_permission?(Permissions::HMRC_ADMIN)
  end

  def to_s
    name
  end
end
