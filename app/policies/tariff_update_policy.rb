TariffUpdatePolicy = Struct.new(:user, :tarif_update) do
  def access?
    user.hmrc_admin?
  end
end
