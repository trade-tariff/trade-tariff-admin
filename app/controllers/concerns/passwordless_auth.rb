module PasswordlessAuth
  extend ActiveSupport::Concern

  included do
    include PunditAuthorization
    before_action :require_authentication, if: :passwordless_authentication?
    helper_method :current_user, :user_session
  end

protected

  def passwordless_authentication?
    TradeTariffAdmin.authenticate_with_passwordless?
  end

  def require_authentication
    return if user_session.present? && !user_session.renew?

    clear_session!
    redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end

  def current_user
    @current_user ||= user_session&.user
  end

  def clear_session!
    user_session&.destroy!
    session[:token] = nil
  end
end
