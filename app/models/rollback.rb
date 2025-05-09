class Rollback
  include ApiEntity

  attr_accessor :id, :keep, :date, :reason
  attr_writer :enqueued_at

  def enqueued_at
    Time.zone.parse(self[:enqueued_at]) if self[:enqueued_at].present?
  end

  def user=(user)
    @attributes[:user_id] = user.id
    @user_id = user.id
  end

  def user
    @user ||= User.find_by(id: user_id)
  end
end
