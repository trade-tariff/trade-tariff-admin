module BasicSessionAuth
  extend ActiveSupport::Concern

  included do
    before_action :require_basic_authentication, if: :require_auth?

    def require_auth?
      TradeTariffAdmin.basic_session_authentication?
    end

    def require_basic_authentication
      unless session[:authenticated]
        redirect_to new_basic_session_path(return_url: request.fullpath)
      end
    end

    # Only define current_user when basic auth is active
    # This prevents it from overriding PasswordlessAuth#current_user
    def current_user
      if TradeTariffAdmin.basic_session_authentication?
        @current_user ||= begin
          user = User.new
          user.name = "tariff"
          user.id = "tariff"
          user
        end
      elsif respond_to?(:user_session, true) && user_session.present?
        # When not using basic auth, delegate to the next auth method
        # Since BasicSessionAuth is included before PasswordlessAuth, we can't use super
        # Instead, check if user_session exists (from PasswordlessAuth) or use SSO
        user_session.user
      elsif respond_to?(:current_user_from_gds_sso, true)
        current_user_from_gds_sso
      end
    end
  end
end
