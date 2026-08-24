class LiveIssuesController < AuthenticatedController
  before_action :disable_service_switching!
  include MultipartDate

  def index
    authorize LiveIssue, :index?
    @live_issues = LiveIssue.all(page: current_page)
  end

  def new
    authorize LiveIssue, :create?
    @live_issue = LiveIssue.new
  end

  def create
    authorize LiveIssue, :create?
    @live_issue = LiveIssue.new(live_issue_params)

    if @live_issue.save && @live_issue.errors.none?
      redirect_to live_issues_path, notice: "Live issue created"
    else
      render "new", alert: "Live issue could not be created: #{@live_issue.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @live_issue = LiveIssue.find(params[:id])
    authorize @live_issue, :update?
  end

  def update
    @live_issue = LiveIssue.find(params[:id])
    authorize @live_issue, :update?
    if @live_issue.update(live_issue_params) && @live_issue.errors.none?
      redirect_to live_issues_path, notice: "Live issue updated"
    else
      redirect_to live_issues_path, alert: "Live issue could not be updated: #{@live_issue.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @live_issue = LiveIssue.find(params[:id])
    authorize @live_issue, :destroy?
    @live_issue.destroy

    redirect_to live_issues_path, notice: "Live issue deleted"
  end

private

  def live_issue_params
    permitted = params.require(:live_issue).permit(
      %i[
        title
        description
        suggested_action
        status
        commodities
      ],
      **multipart_date_params(%w[date_discovered date_resolved]),
    )

    compose_date_params(
      permitted_params: permitted,
      hash: :live_issue,
      date_params: %i[date_discovered date_resolved],
    )
  end
end
