# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    return redirect_to root_path if already_authenticated?

    if decoded_id_token.nil?
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    user = User.from_passwordless_payload!(decoded_id_token)
    return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true unless user

    create_user_session!(user)
    session[:token] = session_token

    redirect_to root_path
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
    cookies.delete(:id_token, domain: TradeTariffAdmin.identity_cookie_domain)
    cookies.delete(:refresh_token, domain: TradeTariffAdmin.identity_cookie_domain)

    redirect_to root_path, notice: "You have been logged out."
  end

private

  def create_user_session!(user)
    Session.create!(
      user: user,
      token: session_token,
      id_token: id_token,
      raw_info: decoded_id_token,
      expires_at: token_expiry,
    )
  end

  def session_token
    @session_token ||= SecureRandom.uuid
  end

  def decoded_id_token
    @decoded_id_token ||= VerifyToken.new(id_token).call
  end

  def id_token
    @id_token ||= cookies[:id_token]
  end

  def user_session
    Session.find_by(token: session[:token])
  end

  def already_authenticated?
    user_session.present? && !user_session.renew?
  end

  def token_expiry
    exp = decoded_id_token&.fetch("exp", nil)
    Time.zone.at(exp.to_i) if exp
  rescue StandardError
    nil
  end
end
