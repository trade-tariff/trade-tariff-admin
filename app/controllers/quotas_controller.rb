class QuotasController < AuthenticatedController
  def new
    @quota_search = QuotaSearch.new
  end

  def search
    @quota_search = QuotaSearch.new(quota_params)

    if @quota_search.valid?
      @quota_definition = QuotaOrderNumbers::QuotaDefinition.find(@quota_search.order_number)
    else
      render 'new'
    end
  end

  def quota_params
    params.require(:quota_search).permit(:order_number)
  end
end
