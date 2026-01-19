require_relative "./trade_tariff_admin"

module TradeTariffAdmin
  class << self
    AUTH_STRATEGIES = %w[basic passwordless].freeze

    def revision
      `cat REVISION 2>/dev/null || git rev-parse --short HEAD`.strip
    end

    def host
      ENV.fetch("ADMIN_HOST", "http://localhost")
    end

    def production?
      ENV["GOVUK_APP_DOMAIN"] == "tariff-admin-production.cloudapps.digital"
    end

    def auth_strategy
      @auth_strategy ||= begin
        strategy = ENV.fetch("AUTH_STRATEGY", "passwordless").to_s.downcase
        strategy = "passwordless" unless AUTH_STRATEGIES.include?(strategy)

        if strategy == "basic" && basic_session_password.blank?
          Rails.logger.warn("AUTH_STRATEGY=basic but BASIC_PASSWORD is missing - falling back to passwordless")
          strategy = "passwordless"
        end

        strategy.to_sym
      end
    end

    def authenticate_with_passwordless?
      auth_strategy == :passwordless
    end

    def basic_session_authentication?
      auth_strategy == :basic
    end

    def basic_session_password
      @basic_session_password ||= ENV["BASIC_PASSWORD"]
    end

    def authorization_enabled?
      authenticate_with_passwordless?
    end

    def identity_consumer_url
      @identity_consumer_url ||= URI.join(identity_base_url, identity_consumer).to_s
    end

    def identity_base_url
      ENV.fetch("IDENTITY_BASE_URL", "http://localhost:3005")
    end

    def identity_encryption_secret
      ENV["IDENTITY_ENCRYPTION_SECRET"]
    end

    def identity_consumer
      @identity_consumer ||= ENV.fetch("IDENTITY_CONSUMER", "admin")
    end

    def identity_cognito_jwks_keys
      return if identity_cognito_jwks_url.blank?

      Rails.cache.fetch("identity_cognito_jwks_keys", expires_in: 1.hour) do
        response = Faraday.get(identity_cognito_jwks_url)

        return JSON.parse(response.body)["keys"] if response.success?

        Rails.logger.error("Failed to fetch JWKS keys: #{response.status} #{response.body}")

        nil
      end
    end

    def identity_cognito_jwks_url
      @identity_cognito_jwks_url ||= ENV["IDENTITY_COGNITO_JWKS_URL"]
    end

    def identity_cognito_issuer_url
      return nil unless identity_cognito_jwks_url

      URI(identity_cognito_jwks_url).tap { |uri|
        uri.path = "/#{uri.path.split('/').find(&:present?)}"
      }.to_s
    end

    def identity_cookie_domain
      @identity_cookie_domain ||= if Rails.env.production?
                                    ".#{base_domain}"
                                  else
                                    :all
                                  end
    end

    def base_domain
      @base_domain ||= begin
        domain = ENV["GOVUK_APP_DOMAIN"]

        unless /(http(s?):).*/.match(domain)
          domain = "https://#{domain}"
        end

        URI.parse(domain).host.sub("admin.", "")
      end
    end

    def environment
      ENV.fetch("ENVIRONMENT", "production")
    end

    def id_token_cookie_name
      cookie_name_for("id_token")
    end

    def refresh_token_cookie_name
      cookie_name_for("refresh_token")
    end

    def cookie_name_for(base_name)
      case environment
      when "production"
        base_name
      else
        "#{environment}_#{base_name}"
      end.to_sym
    end
  end
end
