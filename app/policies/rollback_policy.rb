RollbackPolicy = Struct.new(:user, :rollback) do
  def access?
    user.full_access?
  end
end
