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
