class ApplicationController < ActionController::Base
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
