# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    return redirect_to default_landing_path if already_authenticated?

    result = verify_id_token

    if result.expired?
      # Redirect to identity service with cookies intact so it can refresh the token
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    unless result.valid?
      clear_authentication_cookies
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    user = User.from_passwordless_payload!(result.payload)
    unless user
      clear_authentication_cookies
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    create_user_session!(user, result.payload)
    session[:token] = session_token

    redirect_to default_landing_path
  rescue StandardError => e
    Rails.logger.error("Authentication error: #{e.class}: #{e.message}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def invalid
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    user_session&.destroy!

    session[:token] = nil
    session[:authenticated] = nil
    clear_authentication_cookies

    redirect_to root_path, notice: "You have been logged out."
  end

private

  def create_user_session!(user, payload)
    Session.create!(
      user: user,
      token: session_token,
      id_token: id_token,
      raw_info: payload,
      expires_at: token_expiry(payload),
    )
  end

  def session_token
    @session_token ||= SecureRandom.uuid
  end

  def verify_id_token
    @verify_id_token ||= VerifyToken.new(id_token).call
  end

  def id_token
    @id_token ||= cookies[id_token_cookie_name]
  end

  def user_session
    Session.find_by(token: session[:token])
  end

  def already_authenticated?
    user_session.present? && !user_session.renew?
  end

  def token_expiry(payload)
    exp = payload&.fetch("exp", nil)
    Time.zone.at(exp.to_i) if exp
  rescue StandardError
    nil
  end

  def clear_authentication_cookies
    cookies.delete(id_token_cookie_name, domain: TradeTariffAdmin.identity_cookie_domain)
    cookies.delete(refresh_token_cookie_name, domain: TradeTariffAdmin.identity_cookie_domain)
  end

  def id_token_cookie_name
    TradeTariffAdmin.id_token_cookie_name
  end

  def refresh_token_cookie_name
    TradeTariffAdmin.refresh_token_cookie_name
  end
end
