# A saved combination of a gold query set and a default set of configuration overrides. Created
# once, launched (as a run) many times.
class EvaluationExperiment
  include ApiEntity
  include RecordDateFormatting

  uk_only

  set_collection_path "admin/search/evaluation/experiments"
  set_singular_path "admin/search/evaluation/experiments/:id"

  attributes :name,
             :description,
             :enabled,
             :configuration_overrides,
             :default_scope,
             :gold_query_set_id,
             :created_by,
             :created_at

  # The backend refuses to delete an experiment while one of its runs is queued or running
  # (409) and says why in the reply. Falls back to the same wording when the body is empty.
  DELETE_IN_FLIGHT_MESSAGE = "This experiment cannot be deleted while one of its runs is queued or running. Wait for the run to finish, or cancel it, then try again.".freeze

  def self.conflict_detail(error)
    body = handle_body(error.response)

    (body.dig("errors", 0, "detail") if body.is_a?(Hash)).presence || DELETE_IN_FLIGHT_MESSAGE
  end

  def overridden?
    Array(configuration_overrides).any?
  end

  def created_by_name
    return "-" if created_by.blank?

    User.find_by(uid: created_by)&.name || created_by
  end

  # An experiment that has not been saved has no id to put in the path, so it is created by
  # posting to the collection path. Without this the path would end in a stray "/".
  def singular_path
    persisted? ? super : collection_path
  end
end
