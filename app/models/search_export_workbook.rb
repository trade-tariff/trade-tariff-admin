class SearchExportWorkbook
  include ApiEntity

  attributes :status, :from, :to, :omitted_count, :row_count, :error

  set_collection_path "admin/search_export/workbooks"

  def self.create(from:, to:)
    response = api.post(collection_path, { from:, to: }.to_json, "Content-Type" => "application/json")
    new(parse_jsonapi(response))
  end

  def self.find(id)
    response = api.get("#{collection_path}/#{id}")
    new(parse_jsonapi(response))
  end

  def self.download(id)
    api.get("#{collection_path}/#{id}/download")
  end

  def pending?
    %w[queued running].include?(status)
  end

  def ready?
    status == "ready"
  end
end
