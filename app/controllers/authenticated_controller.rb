class AuthenticatedController < ApplicationController
  # Conditionally include the appropriate auth module based on strategy
  # This ensures only one auth module is included, allowing consistent method names
  case TradeTariffAdmin.auth_strategy
  when :none
    include NoAuth
  when :basic
    include BasicSessionAuth
  when :passwordless
    include PasswordlessAuth
  else
    include NoAuth
  end

  before_action :set_paper_trail_whodunnit

  protect_from_forgery with: :exception

  after_action :verify_authorized, unless: :skip_pundit_verification?

private

  def set_paper_trail_whodunnit
    Current.whodunnit = current_user&.uid
  end

  def skip_pundit_verification?
    false
  end
end
