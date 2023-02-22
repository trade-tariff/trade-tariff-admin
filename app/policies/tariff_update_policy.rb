TariffUpdatePolicy = Struct.new(:user, :tarif_update) do
  def access?
    user.full_access?
  end
end
