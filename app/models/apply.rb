class Apply
  include ApiEntity

  def user
    @user ||= User.find_by(id: user_id)
  end
end
