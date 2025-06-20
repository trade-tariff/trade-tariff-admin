class LiveIssuesController < AuthenticatedController
  before_action :disable_service_switching!
  before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

  def index
    @live_issues = LiveIssue.all(page: current_page)
  end

  def new
    @live_issue = LiveIssue.new
  end

  def create
    @live_issue = LiveIssue.new(live_issue_params)

    if @live_issue.save && @live_issue.errors.none?
      redirect_to live_issues_path, notice: 'Live issue created'
    else
      render 'new', alert: "Live issue could not be created: #{@live_issue.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @live_issue = LiveIssue.find(params[:id])
  end

  def update
    @live_issue = LiveIssue.find(params[:id])
    if @live_issue.update(live_issue_params) && @live_issue.errors.none?
      redirect_to live_issues_path, notice: 'Live issue updated'
    else
      redirect_to live_issues_path, alert: "Live issue could not be updated: #{@live_issue.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @live_issue = LiveIssue.find(params[:id])
    @live_issue.destroy

    redirect_to live_issues_path, notice: 'Live issue deleted'
  end

private

  def live_issue_params
    params.require(:live_issue).permit(
      :title,
      :description,
      :suggested_action,
      :status,
      :date_discovered,
      :date_resolved,
      :commodities,
    )
  end
end
