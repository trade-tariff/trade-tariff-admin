# Who changed which distribution list, how, and when. The recipient is the
# Cognito username (sub). Email addresses must never be stored here.
class DistributionListAuditEvent < ApplicationRecord
  ACTIONS = %w[user_created recipient_added recipient_removed user_deleted].freeze

  validates :actor_uid, :group_name, :recipient_username, presence: true
  validates :action, inclusion: { in: ACTIONS }

  scope :recent_for, ->(group_name) { where(group_name:).order(created_at: :desc, id: :desc) }

  def readonly?
    persisted?
  end
end
