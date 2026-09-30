# One source item of a gold query set: an ATaR ruling or a synthetic ATaR, together with the
# three test searches (gold queries) written for it, one for each persona. The backend keeps
# them as three rows, but an operator reads and edits them as one item.
#
# The id is "<source type>-<source id>", for example "synthetic_atar-12".
class EvaluationGoldQueryItem
  include ApiEntity

  # The personas the backend generator writes, with the words to show for them. The hints
  # describe what the generator writes. They are not limits on what an operator may type.
  PERSONAS = {
    "emu_generic" => { label: "Generic search", hint: "The generator writes 1 to 3 words: how a trader with little knowledge would search." },
    "emu_ordinary" => { label: "Ordinary search", hint: "The generator writes 2 to 6 words." },
    "emu_specific" => { label: "Specific search", hint: "The generator writes 4 to 10 words: how a trader who knows the product well would search." },
  }.freeze

  uk_only

  set_collection_path "admin/search/evaluation/gold_query_sets/:gold_query_set_id/items"
  set_singular_path "admin/search/evaluation/gold_query_sets/:gold_query_set_id/items/:id"

  attributes :gold_query_set_id,
             :source_type,
             :source_id,
             :real_user_search,
             :expected_code,
             :oracle_text,
             *PERSONAS.keys.flat_map { |persona| [:"#{persona}_query", :"#{persona}_notes"] }

  # ApiEntity.find takes a path attribute out of the query string only when it is given
  # with a string key. With a symbol key the set id would also be sent as "?gold_query_set_id=".
  def self.find_in_set(gold_query_set_id, id)
    find(id, "gold_query_set_id" => gold_query_set_id.to_s)
  end

  def synthetic_atar?
    source_type == "synthetic_atar"
  end

  # The history of all three rows, newest first. It is read only: there is no restore,
  # because the expected code is shared by the three rows and restoring one row on its
  # own would leave the item with two different codes.
  def versions
    parse_jsonapi(api.get("#{singular_path}/versions")).map { |attributes| Version.new(attributes) }
  end
end
