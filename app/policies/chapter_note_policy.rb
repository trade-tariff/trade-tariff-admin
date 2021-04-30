ChapterNotePolicy = Struct.new(:user, :chapter_note) do
  def edit?
    user.gds_editor? || user.hmrc_editor?
  end
end
