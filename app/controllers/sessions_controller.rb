# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    log_authentication_context

    return redirect_to default_landing_path if already_authenticated?

    result = verify_id_token

    if result.expired?
      Rails.logger.info("[Auth] Token expired, redirecting to identity service for refresh")
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    unless result.valid?
      Rails.logger.warn("[Auth] Token validation failed: #{result.reason}")
      clear_authentication!
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    user = User.from_passwordless_payload!(result.payload)
    unless user
      Rails.logger.warn("[Auth] User not found for payload sub: #{result.payload&.dig('sub')}")
      clear_authentication!
      return redirect_to TradeTariffAdmin.identity_consumer_url, allow_other_host: true
    end

    Rails.logger.info("[Auth] Successfully authenticated user: #{user.email}")
    create_user_session!(user, result.payload)
    session[:token] = session_token

    redirect_to default_landing_path
  rescue StandardError => e
    Rails.logger.error("[Auth] Authentication error: #{e.class}: #{e.message}")
    Rails.logger.error("[Auth] Backtrace: #{e.backtrace&.first(5)&.join("\n")}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def invalid
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    clear_authentication!(full: true)

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

  def log_authentication_context
    Rails.logger.info("[Auth] Authentication attempt started")
    Rails.logger.info("[Auth] Environment: #{TradeTariffAdmin.environment}")
    Rails.logger.info("[Auth] Cookie domain: #{TradeTariffAdmin.identity_cookie_domain}")
    Rails.logger.info("[Auth] Expected id_token cookie name: #{id_token_cookie_name}")
    Rails.logger.info("[Auth] Expected refresh_token cookie name: #{refresh_token_cookie_name}")
    Rails.logger.info("[Auth] id_token cookie present: #{cookies[id_token_cookie_name].present?}")
    Rails.logger.info("[Auth] refresh_token cookie present: #{cookies[refresh_token_cookie_name].present?}")

    # Log all cookie names (without values) for debugging mismatches
    cookie_names = cookies.to_h.keys
    token_related = cookie_names.select { |name| name.to_s.include?("token") }
    Rails.logger.info("[Auth] All token-related cookies received: #{token_related.inspect}")
  end

  def id_token_cookie_name
    TradeTariffAdmin.id_token_cookie_name
  end

  def refresh_token_cookie_name
    TradeTariffAdmin.refresh_token_cookie_name
  end
end
