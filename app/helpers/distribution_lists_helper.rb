module DistributionListsHelper
  AUDIT_ACTION_LABELS = {
    "user_created" => "Cognito user created",
    "recipient_added" => "Subscribed",
    "recipient_removed" => "Unsubscribed",
    "user_deleted" => "Cognito user and email deleted",
  }.freeze

  def distribution_list_audit_action(action)
    AUDIT_ACTION_LABELS.fetch(action, action.to_s.humanize)
  end

  def distribution_list_audit_time(time)
    time.in_time_zone("London").strftime("%-d %b %Y %H:%M:%S %Z")
  end
end
