UpdatePolicy = Struct.new(:user, :tariff_update) do
  def access?
    user.hmrc_admin?
  end
end
