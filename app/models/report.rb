class Report
  include ApiEntity

  attributes :name, :description, :available, :dependencies_missing, :missing_dependencies

  def run
    api.post("admin/reports/#{to_param}/run")
  end

  def download_redirect_url
    response = api.get("admin/reports/#{to_param}/download")
    response.headers.fetch("location")
  end

  def available?
    available
  end

  def dependencies_missing?
    dependencies_missing
  end
end
