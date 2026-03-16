module NoAuth
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

protected

  def current_user
    @current_user ||= User.basic_auth_user!
  end
end
