class DistributionListsController < AuthenticatedController
  include DistributionListHandling

  def index
    authorize :distribution_list, :index?

    @groups = distribution_list_service.groups
  end

  def show
    authorize :distribution_list, :show?

    @group = distribution_list_service.find_group(params[:group_name])
    @members = distribution_list_service.members(@group.name)
    @form = DistributionListRecipientForm.new
    load_audit_events
  end

private

  # The index page is where Cognito errors redirect to, so an error there
  # must render instead of redirecting back to itself.
  def distribution_lists_unavailable(exception)
    return super unless action_name == "index"

    Rails.logger.error("distribution_list.error #{exception.class.name}: #{exception.message}")
    @groups = []
    flash.now[:alert] = DistributionListHandling::UNAVAILABLE_MESSAGE
    render :index, status: :service_unavailable
  end
end
