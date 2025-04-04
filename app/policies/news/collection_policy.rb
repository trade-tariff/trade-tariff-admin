News::CollectionPolicy = Struct.new(:user, :news_collection) do
  def edit?
    user.gds_editor? || user.hmrc_editor? || user.hmrc_admin?
  end
end
