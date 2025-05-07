class Download
  include ApiEntity

  attr_accessor :user_id

  def user=(user)
    self.user_id = user.id
  end

  def user
    @user ||= User.find_by(id: user_id)
  end
end
