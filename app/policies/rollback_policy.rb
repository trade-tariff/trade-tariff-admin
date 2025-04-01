RollbackPolicy = Struct.new(:user, :rollback) do
  def access?
    user.hmrc_admin? || !TradeTariffAdmin.authenticate_with_sso?
  end
end
