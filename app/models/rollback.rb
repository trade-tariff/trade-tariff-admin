class Rollback
  include ApiEntity
  include FormattedDate

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

  def date=(value)
    @date = normalise_date(value)
  end

  def date
    initialise_date!(@date, use_today: true)
  end
end
