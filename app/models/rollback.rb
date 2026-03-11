class Rollback
  include ApiEntity

  attributes :reason,
             :date,
             :keep,
             :whodunnit

  def enqueued_at
    Time.zone.parse(self[:enqueued_at]) if self[:enqueued_at].present?
  end

  def user
    @user ||= User.find_by(uid: whodunnit)
  end
end
