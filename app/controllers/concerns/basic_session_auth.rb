module BasicSessionAuth
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication, if: :require_auth?
    def require_auth?
      TradeTariffAdmin.basic_session_authentication?
    end

    def require_authentication
      unless session[:authenticated]
        redirect_to new_basic_session_path(return_url: request.fullpath)
      end
    end

    def current_user
      @current_user ||= begin
        user = User.new
        user.name = "tariff"
        user.id = "tariff"
        user
      end
    end
  end
end
