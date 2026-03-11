module VersionMetadata
  extend ActiveSupport::Concern

  included do
    attr_accessor :version_current,
                  :version_oid,
                  :version_previous_oid,
                  :version_has_previous,
                  :version_latest_event
  end

  def current?
    version_current != false
  end

  def deleted?
    version_latest_event == "destroy"
  end

  def has_previous_version?
    version_has_previous == true
  end

  def extract_version_meta!(response)
    body = response.body
    body = JSON.parse(body) if body.is_a?(String)

    return unless body.is_a?(Hash) && body.dig("meta", "version")

    version = body["meta"]["version"]
    self.version_current = version["current"]
    self.version_oid = version["oid"]
    self.version_previous_oid = version["previous_oid"]
    self.version_has_previous = version["has_previous_version"]
    self.version_latest_event = version["latest_event"]
  end
end
