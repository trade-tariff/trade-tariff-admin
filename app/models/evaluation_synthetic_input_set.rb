# A named, saved, frozen sample of synthetic ATaRs -- real, HMRC-analyst-written product
# descriptions, used as-is -- that an experiment can use instead of a gold query set.
# Unlike a gold query set there is no background generation step: sampling happens
# synchronously, so a set is fully built the moment it is created.
class EvaluationSyntheticInputSet
  include ApiEntity
  include RecordDateFormatting

  uk_only

  set_collection_path "admin/search/evaluation/synthetic_input_sets"
  set_singular_path "admin/search/evaluation/synthetic_input_sets/:id"

  attributes :name,
             :requested_size,
             :actual_size,
             :created_by,
             :created_at

  # The backend refuses to delete a set that an experiment still uses (409) and names
  # the experiments in its reply. That sentence is what the operator needs to read.
  def self.conflict_detail(error)
    body = handle_body(error.response)

    body.dig("errors", 0, "detail") if body.is_a?(Hash)
  end

  def created_by_name
    return "-" if created_by.blank?

    User.find_by(uid: created_by)&.name || created_by
  end

  # A set that has not been saved has no id to put in the path, so it is created by
  # posting to the collection path. Without this the path would end in a stray "/".
  def singular_path
    persisted? ? super : collection_path
  end
end
