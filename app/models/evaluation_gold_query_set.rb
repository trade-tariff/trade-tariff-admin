# A named, saved collection of test searches ("gold queries") that an experiment run is
# scored against. The backend builds the set in the background, so a set that was just
# created is still "generating" and its counters grow until it is finished.
class EvaluationGoldQuerySet
  include ApiEntity
  include RecordDateFormatting

  uk_only

  set_collection_path "admin/search/evaluation/gold_query_sets"
  set_singular_path "admin/search/evaluation/gold_query_sets/:id"

  attributes :name,
             :requested_size,
             :atar_percentage,
             :planned_count,
             :generated_count,
             :failed_count,
             :status,
             :failures,
             :created_by,
             :atar_count,
             :synthetic_atar_count,
             :gold_query_count,
             :created_at

  # The backend refuses to delete a set that an experiment still uses (409) and names
  # the experiments in its reply. That sentence is what the operator needs to read.
  def self.conflict_detail(error)
    body = handle_body(error.response)

    body.dig("errors", 0, "detail") if body.is_a?(Hash)
  end

  def generating?
    status == "generating"
  end

  # Items that have either produced their queries or definitely failed.
  def finished_count
    generated_count.to_i + failed_count.to_i
  end

  # How many source items the set holds now. Operators can delete items, so this can be
  # lower than the number that were generated.
  def item_count
    atar_count.to_i + synthetic_atar_count.to_i
  end

  def synthetic_atar_percentage
    100 - atar_percentage.to_i
  end

  def failure_list
    Array(failures)
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
