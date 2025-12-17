UserPolicy = Struct.new(:user, :target_user) do
  def edit?
    return true if TradeTariffAdmin.basic_session_authentication?
    return false unless user

    user.technical_operator?
  end

  def update?
    return true if TradeTariffAdmin.basic_session_authentication?
    return false unless user

    user.technical_operator?
  end
end

