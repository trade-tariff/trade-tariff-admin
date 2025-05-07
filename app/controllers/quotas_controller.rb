class QuotasController < AuthenticatedController
  def show
    quota_definition
  end

  def new
    return render 'errors/not_found' if TradeTariffAdmin::ServiceChooser.xi?

    @quota_search = QuotaSearch.new
  end

  def search
    return render 'errors/not_found' if TradeTariffAdmin::ServiceChooser.xi?

    @quota_search = QuotaSearch.new(quota_params)

    if @quota_search.valid? && current_quota_definition
      render perform_search_quotas_path
    elsif !@quota_search.valid?
      render new_quota_path
    elsif !current_quota_definition
      redirect_to new_quota_path, alert: "Quota #{@quota_search.order_number} not found."
    end
  end

  def current_quota_definition
    @current_quota_definition ||= quota_definitions.max_by(&:validity_end_date)
  rescue Faraday::ResourceNotFound
    nil
  end

  def quota_definition
    @quota_definition ||= QuotaOrderNumbers::QuotaDefinition.find(
      params[:id],
      quota_order_number_id: params[:order_number],
    )
  end

  def quota_definitions
    @quota_definitions ||= QuotaOrderNumbers::QuotaDefinition.all(quota_order_number_id: @quota_search.order_number)
  end

  def quota_params
    params.require(:quota_search).permit(:order_number)
  end
end
