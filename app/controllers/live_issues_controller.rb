class LiveIssuesController < AuthenticatedController
  before_action :disable_service_switching!
  before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

  def index
    @live_issues = LiveIssue.all(page: current_page)
    render 'index'
  end

end
