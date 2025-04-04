SearchReferencePolicy = Struct.new(:user, :search_reference) do
  def edit?
    user.gds_editor? || user.hmrc_editor? || user.hmrc_admin?
  end
end
