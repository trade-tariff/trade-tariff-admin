class ApplicationController < ActionController::Base
  include PunditAuthorization

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

  # Provide a default current_user method for error pages and other contexts
  # where authentication might not be available
  def current_user
    nil
  end
  helper_method :current_user

  def default_landing_path
    return references_sections_path if current_user&.hmrc_admin?

    root_path
  end
  helper_method :default_landing_path
end
