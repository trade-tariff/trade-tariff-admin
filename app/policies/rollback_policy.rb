RollbackPolicy = Struct.new(:user, :rollback) do
  def access?
    user.technical_operator?
  end
end
