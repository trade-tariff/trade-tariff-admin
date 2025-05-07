class Rollback
  include ApiEntity

  attributes :reason,
             :date,
             :keep,
             :user_id

  def enqueued_at
    Time.zone.parse(self[:enqueued_at]) if self[:enqueued_at].present?
  end

  def user
    @user ||= User.find_by(id: user_id)
  end
end
