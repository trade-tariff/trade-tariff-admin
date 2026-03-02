class GoodsNomenclatureLabelsController < AuthenticatedController
  def index
    authorize GoodsNomenclatureLabel, :index?

    respond_to do |format|
      format.html do
        @stats = GoodsNomenclatureLabelStats.fetch
      rescue Faraday::Error => e
        Rails.logger.error("Failed to fetch label stats: #{e.message}")
        @stats = nil
      end
      format.json { render json: labels_json }
    end
  end

  def search
    authorize GoodsNomenclatureLabel, :index?

    commodity_code = normalize_commodity_code(search_params[:commodity_code])

    if commodity_code.blank?
      redirect_to goods_nomenclature_labels_path, alert: "Please enter a commodity code."
      return
    end

    unless valid_commodity_code?(commodity_code)
      redirect_to goods_nomenclature_labels_path, alert: "Commodity code must be 10 digits."
      return
    end

    redirect_to goods_nomenclature_label_path(commodity_code)
  end

  def show
    authorize GoodsNomenclatureLabel, :show?

    @goods_nomenclature_label = find_label
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_labels_path, alert: "Label not found for commodity code #{goods_nomenclature_id}."
  end

  def update
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label = find_label

    @goods_nomenclature_label.assign_attributes(label_attributes)

    if @goods_nomenclature_label.save && @goods_nomenclature_label.errors.empty?
      redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                  notice: "Label updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_labels_path, alert: "Label not found for commodity code #{goods_nomenclature_id}."
  end

private

  def labels_json
    labels = GoodsNomenclatureLabel.all(
      page: params[:page] || 1,
      type: params[:type] || "commodity",
      sort: params[:sort] || "score",
      direction: params[:direction] || "asc",
      status: params[:status],
      score_category: params[:score_category],
      q: params[:q],
    )

    {
      data: labels.map do |label|
        {
          goods_nomenclature_sid: label.goods_nomenclature_sid,
          goods_nomenclature_item_id: label.goods_nomenclature_item_id,
          score: label.score,
          stale: label.stale,
          manually_edited: label.manually_edited,
          description: label.original_description.to_s.truncate(80),
        }
      end,
      pagination: {
        page: labels.respond_to?(:current_page) ? labels.current_page : 1,
        per_page: labels.respond_to?(:limit_value) ? labels.limit_value : 20,
        total_count: labels.respond_to?(:total_count) ? labels.total_count : labels.size,
        total_pages: labels.respond_to?(:total_pages) ? labels.total_pages : 1,
      },
    }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch labels: #{e.message}")
    { data: [], pagination: { page: 1, per_page: 20, total_count: 0, total_pages: 0 } }
  end

  def find_label
    GoodsNomenclatureLabel.find(goods_nomenclature_id)
  end

  def goods_nomenclature_id
    params[:goods_nomenclature_id]
  end

  def search_params
    params.permit(:commodity_code)
  end

  def label_params
    params.require(:goods_nomenclature_label).permit(
      :description,
      :known_brands_text,
      :colloquial_terms_text,
      :synonyms_text,
    )
  end

  def label_attributes
    attrs = {}
    attrs[:labels] = @goods_nomenclature_label.labels&.dup || {}

    if label_params[:description].present? || label_params[:description] == ""
      attrs[:labels]["description"] = label_params[:description]
    end

    if label_params[:known_brands_text]
      attrs[:labels]["known_brands"] = text_to_array(label_params[:known_brands_text])
    end

    if label_params[:colloquial_terms_text]
      attrs[:labels]["colloquial_terms"] = text_to_array(label_params[:colloquial_terms_text])
    end

    if label_params[:synonyms_text]
      attrs[:labels]["synonyms"] = text_to_array(label_params[:synonyms_text])
    end

    attrs
  end

  def text_to_array(text)
    return [] if text.blank?

    text.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end

  def normalize_commodity_code(code)
    code.to_s.gsub(/\s+/, "")
  end

  def valid_commodity_code?(code)
    code.match?(/\A\d{10}\z/)
  end
end
