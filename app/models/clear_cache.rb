class ClearCache
  include Her::JsonApi::Model

  attributes :user_id

  collection_path '/admin/clear_caches'

  def user=(user)
    self.user_id = user.id
  end

  def user
    @user ||= User.find_by(id: user_id)
  end
end
