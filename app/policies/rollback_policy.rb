RollbackPolicy = Struct.new(:user, :rollback) do
  def access?
    user.hmrc_admin?
  end
end
