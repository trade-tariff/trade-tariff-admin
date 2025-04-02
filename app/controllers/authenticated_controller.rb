class AuthenticatedController < ApplicationController
  if TradeTariffAdmin.authenticate_with_sso?
    include Pundit::Authorization
    include GDS::SSO::ControllerMethods
    prepend_before_action :authenticate_user!

    rescue_from Pundit::NotAuthorizedError do |e|
      # Layout and view comes from GDS::SSO::ControllerMethods
      render 'authorisations/unauthorised', layout: 'unauthorised', status: :forbidden, locals: { message: e.message }
    end

  else
    before_action :require_authentication, if: :require_auth?

    def require_auth?
      TradeTariffAdmin.basic_authentication?
    end

    def require_authentication
      unless session[:authenticated]
        redirect_to new_basic_session_path(return_url: request.fullpath)
      end
    end
  end

  protect_from_forgery with: :exception
end
