class Download
  include Her::JsonApi::Model

  attributes :user_id

  collection_path '/admin/downloads'


  def user=(user)
    self.user_id = user.id
  end

  def user
    @user ||= User.find_by(id: user_id)
  end

end
