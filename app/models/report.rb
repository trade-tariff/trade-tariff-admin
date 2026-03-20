class Report
  include ApiEntity

  attributes :name, :description, :available, :dependencies_missing, :missing_dependencies, :download_url, :supports_email

  def run
    api.post("admin/reports/#{to_param}/run")
  end

  def send_email
    api.post("admin/reports/#{to_param}/send_email")
  end

  def download_redirect_url
    download_url
  end

  def available?
    available
  end

  def dependencies_missing?
    dependencies_missing
  end
end
