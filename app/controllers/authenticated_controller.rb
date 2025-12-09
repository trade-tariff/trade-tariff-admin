class AuthenticatedController < ApplicationController
  include PasswordlessAuth
  include BasicSessionAuth
  include SsoAuth

  protect_from_forgery with: :exception
end
