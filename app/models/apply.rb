class Apply
  include ApiEntity

  def user
    @user ||= User.find_by(uid: whodunnit)
  end
end
