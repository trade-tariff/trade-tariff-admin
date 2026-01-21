class ApplicationController < ActionController::Base
  include PunditAuthorization

  def current_page
    Integer(params[:page] || 1)
  end

  def disable_service_switching!
    @disable_service_switching = true
  end

  def service_switcher_enabled?
    !@disable_service_switching == true
  end

  helper_method :service_switcher_enabled?

  # Provide a default current_user method for error pages and other contexts
  # where authentication might not be available
  def current_user
    nil
  end
  helper_method :current_user

  def default_landing_path
    return references_sections_path if current_user&.hmrc_admin?

    root_path
  end
  helper_method :default_landing_path

  # NOTE: Cleanup of all authentication state:
  # 1. Database Session record
  # 2. Rails session variables
  # 3. Authentication cookies
  def clear_authentication!(full: false)
    Rails.logger.info("[Auth] Clearing session (PasswordlessAuth)")

    # Destroy database session record
    if user_session.present?
      Rails.logger.info("[Auth] Destroying database session for user: #{user_session.user&.email}")
      user_session.destroy!
    end

    # Clear Rails session variables
    session[:token] = nil
    session[:authenticated] = nil

    # Delete authentication cookies
    cookies.delete(TradeTariffAdmin.id_token_cookie_name, domain: TradeTariffAdmin.identity_cookie_domain)
    # Delete refresh token only on full logout
    cookies.delete(TradeTariffAdmin.refresh_token_cookie_name, domain: TradeTariffAdmin.identity_cookie_domain) if full

    Rails.logger.info("[Auth] Session cleared")
  end
end
