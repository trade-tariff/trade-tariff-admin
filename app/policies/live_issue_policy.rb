LiveIssuePolicy = Struct.new(:user, :live_issue) do
  def edit?
    user.gds_editor? || user.hmrc_editor? || user.hmrc_admin?
  end
end
