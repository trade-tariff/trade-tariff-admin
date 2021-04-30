SearchReferencePolicy = Struct.new(:user, :search_reference) do
  def edit?
    user.gds_editor? || user.hmrc_editor?
  end
end
