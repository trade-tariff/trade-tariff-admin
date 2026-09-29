class TariffKnowledgeSyntheticAtar
  include ApiEntity
  include RecordDateFormatting

  uk_only

  attributes :chapter,
             :real_user_search,
             :times_searched,
             :likely_heading,
             :description,
             :goods_nomenclature_item_id,
             :notes,
             :completed_by,
             :created_at,
             :updated_at

  def self.bulk_import(csv_content)
    response = api.post("admin/tariff_knowledge_synthetic_atars/bulk_import", bulk_import_payload(csv_content))
    attributes = handle_body(response).dig("data", "attributes") || {}

    BulkImportResult.new(
      created: attributes["created"].to_i,
      updated: attributes["updated"].to_i,
      unchanged: attributes["unchanged"].to_i,
      skipped: attributes["skipped"].to_i,
    )
  rescue Faraday::UnprocessableEntityError => e
    BulkImportResult.new(errors: Array(handle_body(e.response)["errors"]))
  rescue Faraday::Error => e
    Rails.logger.error("Failed to bulk import synthetic ATaRs: #{e.message}")
    BulkImportResult.new(errors: [{ "detail" => "The import could not be completed. Check the list before you try again. Uploading the same file again is safe." }])
  end

  def self.bulk_import_payload(csv_content)
    {
      data: {
        type: "tariff_knowledge_synthetic_atar_bulk_import",
        attributes: {
          csv: csv_content,
        },
      },
    }
  end

  def description_summary
    description.to_s.truncate(90)
  end

  def times_searched_label
    times_searched.presence || "-"
  end

  class BulkImportResult
    attr_reader :created, :updated, :unchanged, :skipped, :errors

    def initialize(created: 0, updated: 0, unchanged: 0, skipped: 0, errors: [])
      @created = created
      @updated = updated
      @unchanged = unchanged
      @skipped = skipped
      @errors = errors
    end

    def total
      created + updated + unchanged
    end

    def success?
      errors.blank?
    end

    def message
      "Imported #{total} #{'synthetic ATaR'.pluralize(total)}: #{created} created, #{updated} updated, #{unchanged} unchanged. " \
        "#{skipped} #{'row'.pluralize(skipped)} skipped because they are not finished."
    end
  end
end
