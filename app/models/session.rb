class Session < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :id_token, presence: true

  def current?
    !renew?
  end

  def renew?
    !verify_id_token.valid? || token_expired?
  end

  def cookie_token_match_for?(cookie_token)
    id_token == cookie_token.to_s
  end

private

  def verify_id_token
    @verify_id_token ||= VerifyToken.new(id_token).call
  end

  def token_expired?
    expires_at.present? && expires_at.past?
  end
end
