class AuthenticatedController < ApplicationController
  include Pundit::Authorization
  include GDS::SSO::ControllerMethods

  protect_from_forgery

  prepend_before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError do |e|
    # Layout and view comes from GDS::SSO::ControllerMethods
    render 'authorisations/unauthorised', layout: 'unauthorised', status: :forbidden, locals: { message: e.message }
  end

  def current_page
    Integer(params[:page] || 1)
  end

  def disable_service_switching!
    @disable_service_switching = true
  end

  def service_switcher_enabled?
    !@disable_service_switching == true
  end
  helper_method :service_switcher_enabled?
end
