class QuotasController < AuthenticatedController
  def search
    @quota_search = QuotaSearch.new
  end

  def search_results
    @quota_search = QuotaSearch.new(params[:quota_search][:order_number])

    if @quota_search.valid?
      # Calls to the quota search/filter
    else
      render 'quotas/search'
    end
  end
end
