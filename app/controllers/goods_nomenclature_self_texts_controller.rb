class GoodsNomenclatureSelfTextsController < AuthenticatedController
  before_action :uk_only
  before_action :load_self_text, only: %i[show score regenerate approve reject update]

  def index
    authorize GoodsNomenclatureSelfText, :index?

    respond_to do |format|
      format.html
      format.json { render json: self_texts_json }
    end
  end

  def search
    authorize GoodsNomenclatureSelfText, :index?

    commodity_code = normalize_commodity_code(search_params[:commodity_code])

    if commodity_code.blank?
      redirect_to goods_nomenclature_self_texts_path, alert: "Please enter a commodity code."
      return
    end

    unless valid_commodity_code?(commodity_code)
      redirect_to goods_nomenclature_self_texts_path, alert: "Commodity code must be 10 digits."
      return
    end

    redirect_to goods_nomenclature_self_text_path(commodity_code)
  end

  def show
    authorize GoodsNomenclatureSelfText, :show?
  end

  def score
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.generate_score

    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                notice: "Score generated successfully."
  rescue Faraday::Error
    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                alert: "Failed to generate score."
  end

  def regenerate
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.regenerate

    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                notice: "Self-text regenerated successfully."
  rescue Faraday::Error
    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                alert: "Failed to regenerate self-text."
  end

  def approve
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.approve

    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                notice: "Self-text approved."
  rescue Faraday::Error
    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                alert: "Failed to approve self-text."
  end

  def reject
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.reject

    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                notice: "Self-text marked for review."
  rescue Faraday::Error
    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                alert: "Failed to reject self-text."
  end

  def update
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.assign_attributes(self_text: self_text_params[:self_text])

    if @self_text.save && @self_text.errors.empty?
      redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                  notice: "Self-text updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

private

  def load_self_text
    @self_text = GoodsNomenclatureSelfText.find(goods_nomenclature_id)
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_self_texts_path, alert: "Self-text not found for commodity code #{goods_nomenclature_id}."
  end

  def self_texts_json
    self_texts = GoodsNomenclatureSelfText.all(
      page: params[:page] || 1,
      type: params[:type] || "commodity",
      sort: params[:sort] || "score",
      direction: params[:direction] || "asc",
      status: params[:status],
      score_category: params[:score_category],
    )

    {
      data: self_texts.map do |st|
        {
          goods_nomenclature_item_id: st.goods_nomenclature_item_id,
          score: st.score,
          needs_review: st.needs_review,
          stale: st.stale,
          manually_edited: st.manually_edited,
          self_text: st.self_text.to_s.truncate(80),
        }
      end,
      pagination: {
        page: self_texts.respond_to?(:current_page) ? self_texts.current_page : 1,
        per_page: self_texts.respond_to?(:limit_value) ? self_texts.limit_value : 20,
        total_count: self_texts.respond_to?(:total_count) ? self_texts.total_count : self_texts.size,
        total_pages: self_texts.respond_to?(:total_pages) ? self_texts.total_pages : 1,
      },
    }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch self-texts: #{e.message}")
    { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
  end

  def uk_only
    return if TradeTariffAdmin::ServiceChooser.uk?

    render "errors/not_found"
  end

  def goods_nomenclature_id
    params[:goods_nomenclature_id]
  end

  def search_params
    params.permit(:commodity_code)
  end

  def self_text_params
    params.require(:goods_nomenclature_self_text).permit(:self_text)
  end

  def normalize_commodity_code(code)
    code.to_s.gsub(/\s+/, "")
  end

  def valid_commodity_code?(code)
    code.match?(/\A\d{10}\z/)
  end
end
