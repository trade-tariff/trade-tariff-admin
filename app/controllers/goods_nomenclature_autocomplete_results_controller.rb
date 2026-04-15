class GoodsNomenclatureAutocompleteResultsController < AuthenticatedController
  def index
    authorize DescriptionIntercept, :update?

    render json: GoodsNomenclatureAutocompleteResult.listing(
      params[:q],
      filters: { goods_nomenclature_class: %w[Chapter Heading] },
    )
  end
end
