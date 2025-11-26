class DecodeJwt
  def initialize(token)
    @token = token
  end

  def call
    return if token.blank?

    decoded = if Rails.env.development?
                JWT.decode(token, nil, false)
              else
                keys = identity_cognito_jwks_keys
                return if keys.blank?

                config = {
                  algorithms: %w[RS256],
                  jwks: { keys: keys },
                  iss: identity_cognito_issuer_url,
                  verify_iss: true,
                }

                JWT.decode(token, nil, true, config)
              end

    decoded.try(:[], 0)
  end

private

  delegate :identity_cognito_issuer_url,
           :identity_cognito_jwks_keys,
           to: TradeTariffAdmin

  attr_reader :token
end
