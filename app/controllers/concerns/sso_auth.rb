module SsoAuth
  extend ActiveSupport::Concern

  included do
    include PunditAuthorization
    include GDS::SSO::ControllerMethods
    prepend_before_action :authenticate_user!, if: :sso_authentication?
  end

private

  def sso_authentication?
    TradeTariffAdmin.authenticate_with_sso?
  end
end
