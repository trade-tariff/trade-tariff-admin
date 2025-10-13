class CdsUpdateNotification
  include ApiEntity

  attributes :filename,
             :user_id

  def user
    @user ||= User.find_by(id: user_id)
  end
end
