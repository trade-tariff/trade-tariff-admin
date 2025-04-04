SectionNotePolicy = Struct.new(:user, :section_note) do
  def edit?
    user.gds_editor? || user.hmrc_editor? || user.hmrc_admin?
  end
end
