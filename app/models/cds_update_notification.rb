class CdsUpdateNotification
  include ApiEntity

  attributes :filename,
             :whodunnit

  def user
    @user ||= User.find_by(uid: whodunnit)
  end
end
