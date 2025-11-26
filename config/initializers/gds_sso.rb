# Only configure GDS SSO when using SSO authentication strategy
auth_strategy = ENV.fetch("AUTH_STRATEGY", "sso").to_s.downcase
auth_strategy = "sso" unless %w[basic sso passwordless].include?(auth_strategy)

if auth_strategy == "sso"
  GDS::SSO.config do |config|
    config.user_model   = 'User'
    config.oauth_id     = ENV['TARIFF_ADMIN_OAUTH_ID'] || 'abcdefghjasndjkasndtariffadmin'
    config.oauth_secret = ENV['TARIFF_ADMIN_OAUTH_SECRET'] || 'secret'
    config.oauth_root_url = Plek.find('signon')
  end
end
