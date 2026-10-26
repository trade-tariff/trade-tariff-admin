# One synthetic ATaR frozen into a synthetic input set when the set was created. The query
# and expected code are copies taken then, not the synthetic ATaR's current values. Items are
# only ever listed: a set's contents are fixed, so nothing fetches, edits or deletes one.
class EvaluationSyntheticInputSetItem
  include ApiEntity

  uk_only

  set_collection_path "admin/search/evaluation/synthetic_input_sets/:synthetic_input_set_id/items"
  # ApiEntity fills the set id into the collection path only when a singular path declares it
  # too, so this is set even though no single item is ever requested.
  set_singular_path "admin/search/evaluation/synthetic_input_sets/:synthetic_input_set_id/items/:id"

  attributes :synthetic_input_set_id,
             :synthetic_atar_id,
             :query,
             :expected_code
end
