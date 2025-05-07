require_relative './trade_tariff_admin'

module TradeTariffAdmin
  class << self
    def revision
      `cat REVISION 2>/dev/null || git rev-parse --short HEAD`.strip
    end

    def host
      ENV.fetch('ADMIN_HOST', 'http://localhost')
    end

    def production?
      ENV['GOVUK_APP_DOMAIN'] == 'tariff-admin-production.cloudapps.digital'
    end

    def authenticate_with_sso?
      @authenticate_with_sso ||= ENV.fetch('AUTHENTICATE_WITH_SSO', 'true') == 'true'
    end

    def basic_session_authentication?
      @basic_session_authentication ||= !authenticate_with_sso? && basic_session_password.present?
    end

    def basic_session_password
      @basic_session_password ||= ENV['BASIC_PASSWORD']
    end
  end
end
