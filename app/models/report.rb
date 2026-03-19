class Report
  include ApiEntity

  set_singular_path "admin/reports/:id"
  set_collection_path "admin/reports"

  attributes :name, :description, :available, :dependencies_missing, :missing_dependencies

  def run
    api.post("admin/reports/#{to_param}/run")
  end

  def download_url
    [TradeTariffAdmin::ServiceChooser.api_host, "admin", "reports", to_param, "download"].join("/")
  end

  def available?
    available
  end

  def dependencies_missing?
    dependencies_missing
  end
end
