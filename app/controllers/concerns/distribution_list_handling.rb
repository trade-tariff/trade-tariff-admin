# Shared behaviour for the distribution list pages. Recipient emails are only
# ever rendered in the response, so these pages must not be cached and flash
# messages must never contain an email. Nothing is cached, so every page shows
# the current state of Cognito.
module DistributionListHandling
  extend ActiveSupport::Concern

  UNAVAILABLE_MESSAGE = "Distribution lists are unavailable. Try again later.".freeze
  LIST_NOT_FOUND_MESSAGE = "Distribution list not found.".freeze
  AUDIT_EVENTS_SHOWN = 20

  included do
    before_action :disable_caching

    # Registered first so the more specific handlers below are checked first.
    rescue_from DistributionListService::Error, with: :distribution_lists_unavailable
    rescue_from DistributionListService::InvalidGroup, with: :distribution_list_not_found
    rescue_from DistributionListService::NotFound, with: :distribution_list_not_found
  end

private

  def distribution_list_service
    @distribution_list_service ||= DistributionListService.new(actor: current_user)
  end

  def load_audit_events
    @audit_events = DistributionListAuditEvent.recent_for(@group.name).limit(AUDIT_EVENTS_SHOWN)
  end

  def disable_caching
    response.headers["Cache-Control"] = "no-store"
  end

  def distribution_lists_unavailable(exception)
    Rails.logger.error("distribution_list.error #{exception.class.name}: #{exception.message}")
    redirect_to distribution_lists_path, alert: UNAVAILABLE_MESSAGE
  end

  def distribution_list_not_found
    redirect_to distribution_lists_path, alert: LIST_NOT_FOUND_MESSAGE
  end
end
