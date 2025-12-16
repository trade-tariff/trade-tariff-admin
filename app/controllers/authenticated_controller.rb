class AuthenticatedController < ApplicationController
  # Conditionally include the appropriate auth module based on strategy
  # This ensures only one auth module is included, allowing consistent method names
  case TradeTariffAdmin.auth_strategy
  when :basic
    include BasicSessionAuth
  when :passwordless
    include PasswordlessAuth
  else
    include PasswordlessAuth
  end

  protect_from_forgery with: :exception
end
