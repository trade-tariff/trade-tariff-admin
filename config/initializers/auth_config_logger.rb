# frozen_string_literal: true

# Log authentication configuration at startup for debugging
Rails.application.config.after_initialize do
  next if Rails.env.test?

  Rails.logger.info("[Auth Config] ========================================")
  Rails.logger.info("[Auth Config] Authentication Configuration at Startup")
  Rails.logger.info("[Auth Config] ========================================")
  Rails.logger.info("[Auth Config] Auth strategy: #{TradeTariffAdmin.auth_strategy}")
  Rails.logger.info("[Auth Config] Environment: #{TradeTariffAdmin.environment}")
  Rails.logger.info("[Auth Config] id_token cookie name: #{TradeTariffAdmin.id_token_cookie_name}")
  Rails.logger.info("[Auth Config] refresh_token cookie name: #{TradeTariffAdmin.refresh_token_cookie_name}")
  Rails.logger.info("[Auth Config] Cookie domain: #{TradeTariffAdmin.identity_cookie_domain}")
  Rails.logger.info("[Auth Config] Identity base URL: #{TradeTariffAdmin.identity_base_url}")
  Rails.logger.info("[Auth Config] Identity consumer: #{TradeTariffAdmin.identity_consumer}")
  Rails.logger.info("[Auth Config] Identity consumer URL: #{TradeTariffAdmin.identity_consumer_url}")
  Rails.logger.info("[Auth Config] JWKS URL configured: #{TradeTariffAdmin.identity_cognito_jwks_url.present?}")
  Rails.logger.info("[Auth Config] Encryption secret configured: #{TradeTariffAdmin.identity_encryption_secret.present?}")

  # Warn about potential misconfigurations
  if TradeTariffAdmin.auth_strategy == :passwordless
    if TradeTariffAdmin.identity_cognito_jwks_url.blank?
      Rails.logger.warn("[Auth Config] WARNING: IDENTITY_COGNITO_JWKS_URL is not set - token verification will fail!")
    end

    if TradeTariffAdmin.identity_encryption_secret.blank? && !Rails.env.development?
      Rails.logger.warn("[Auth Config] WARNING: IDENTITY_ENCRYPTION_SECRET is not set - token decryption will fail!")
    end
  end

  Rails.logger.info("[Auth Config] ========================================")
end
