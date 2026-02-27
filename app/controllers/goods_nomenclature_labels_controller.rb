class GoodsNomenclatureLabelsController < AuthenticatedController
  before_action :uk_only

  def index
    authorize GoodsNomenclatureLabel, :index?
    @stats = GoodsNomenclatureLabelStats.fetch
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch label stats: #{e.message}")
    @stats = nil
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

  def uk_only
    return if TradeTariffAdmin::ServiceChooser.uk?

    render "errors/not_found"
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
