UpdatePolicy = Struct.new(:user, :tariff_update) do
  def access?
    user.technical_operator?
  end
end
