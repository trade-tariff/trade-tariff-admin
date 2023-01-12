class QuotasController < AuthenticatedController
  def new
    return render 'errors/not_found' if TradeTariffAdmin::ServiceChooser.xi?

    @quota_search = QuotaSearch.new
  end

  def search
    return render 'errors/not_found' if TradeTariffAdmin::ServiceChooser.xi?

    @quota_search = QuotaSearch.new(quota_params)

    if @quota_search.valid? && quota_definition
      render perform_quota_search_path
    elsif !@quota_search.valid?
      render quota_search_path
    elsif !quota_definition
      redirect_to quota_search_path, alert: "Quota #{@quota_search.order_number} not found."
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
