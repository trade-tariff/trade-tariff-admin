# Shared behaviour for the distribution list pages. Recipient emails are only
# ever rendered in the response, so these pages must not be cached and flash
# messages must never contain an email. Nothing is cached, so every page shows
# the current state of Cognito.
module DistributionListHandling
  extend ActiveSupport::Concern

  UNAVAILABLE_MESSAGE = "Distribution lists are unavailable. Try again later.".freeze
  LIST_NOT_FOUND_MESSAGE = "Distribution list not found.".freeze
  BUSY_MESSAGE = "Another change to this recipient is in progress. Try again.".freeze
  AUDIT_EVENTS_SHOWN = 20

  included do
    before_action :disable_caching

    # Registered first so the more specific handlers below are checked first.
    rescue_from DistributionListService::Error, with: :distribution_lists_unavailable
    rescue_from DistributionListService::InvalidGroup, with: :distribution_list_not_found
    rescue_from DistributionListService::NotFound, with: :distribution_list_not_found
    rescue_from DistributionListService::Busy, with: :distribution_list_busy
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
    redirect_to distribution_lists_path, alert: with_missing_audits(UNAVAILABLE_MESSAGE, exception)
  end

  # Appends the audit events that could not be saved, named by action and
  # Cognito username (never by email), so the operator can have them recorded.
  def with_missing_audits(message, error)
    failures = error.is_a?(DistributionListService::AuditFailed) ? error.failures : error.failed_audits
    return message if failures.empty?

    missing = failures.map { |f| "#{f[:action]} for Cognito user #{f[:username]}" }.join("; ")
    "#{message} The audit record could not be saved. Ask the platform team to record: #{missing}."
  end

  def distribution_list_busy
    redirect_to @group ? distribution_list_path(@group.name) : distribution_lists_path, alert: BUSY_MESSAGE
  end

  def distribution_list_not_found
    redirect_to distribution_lists_path, alert: LIST_NOT_FOUND_MESSAGE
  end
end
