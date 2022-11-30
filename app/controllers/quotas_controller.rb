class QuotasController < AuthenticatedController
  def new
    @quota_search = QuotaSearch.new
  end

  def search
    @quota_search = QuotaSearch.new(quota_params)

    if @quota_search.valid? && quota_definition
      render perform_search_quotas_path
    elsif !@quota_search.valid?
      render new_quota_path
    elsif !quota_definition
      redirect_to new_quota_path, alert: "Quota #{@quota_search.order_number} not found."
    end
  end

  def quota_definition
    @quota_definition = QuotaOrderNumbers::QuotaDefinition.find(@quota_search.order_number)
  rescue Faraday::ResourceNotFound
    nil
  end

  def quota_params
    params.require(:quota_search).permit(:order_number)
  end
end
