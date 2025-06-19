class LiveIssuesController < AuthenticatedController
  before_action :disable_service_switching!
  before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

  def index
    @live_issues = LiveIssue.all(page: current_page)
    render 'index'
  end

  def new
    @live_issue = LiveIssue.new
    render 'new'
  end

  def create
    @live_issue = LiveIssue.new(live_issue_params)
    @live_issue.save

    if @live_issue.errors.none?
      redirect_to live_issues_path, notice: 'Live issue created'
    else
      render 'new'
    end
  end

private

  def live_issue_params
    params.require(:live_issue).permit(
      :title,
      :description,
      :suggested_action,
      :date_discovered,
      :date_resolved,
      :commodities,
      status: []
    )
  end
end
