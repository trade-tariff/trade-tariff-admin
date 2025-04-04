class AuthenticatedController < ApplicationController
  if TradeTariffAdmin.authenticate_with_sso?
    include SsoAuth
  else
    include BasicSessionAuth
  end

  protect_from_forgery with: :exception
end
