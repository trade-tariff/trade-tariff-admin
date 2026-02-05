module PasswordlessAuth
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication, if: :passwordless_authentication?
    helper_method :current_user, :user_session
  end

protected

  def passwordless_authentication?
    TradeTariffAdmin.authenticate_with_passwordless?
  end

  def require_authentication
    return if authenticated?

    clear_authentication!
    redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end

  def current_user
    @current_user ||= user_session&.user
  end

  def authenticated?
    user_session.present? &&
      user_session.cookie_token_match_for?(cookies[TradeTariffAdmin.id_token_cookie_name]) &&
      user_session.current?
  end
end
