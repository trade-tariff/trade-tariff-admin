class GoodsNomenclatureLabelsController < AuthenticatedController
  before_action :load_label, only: %i[score regenerate approve reject]

  def index
    authorize GoodsNomenclatureLabel, :index?

    respond_to do |format|
      format.html { redirect_to goods_nomenclature_self_texts_path(anchor: "labels") }
      format.json { render json: GoodsNomenclatureLabel.listing(params) }
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
    @versions = fetch_versions
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_labels_path, alert: "Label not found for commodity code #{goods_nomenclature_id}."
  end

  def update
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label = find_label(skip_oid: true)

    @goods_nomenclature_label.assign_attributes(label_attributes)

    if @goods_nomenclature_label.save && @goods_nomenclature_label.errors.empty?
      redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                  notice: "Label updated successfully."
    else
      @versions = fetch_versions
      render :show, status: :unprocessable_content
    end
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_labels_path, alert: "Label not found for commodity code #{goods_nomenclature_id}."
  end

  def score
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label.generate_score

    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                notice: "Label score generated successfully."
  rescue Faraday::Error => e
    Rails.logger.error("Failed to generate label score for #{goods_nomenclature_id}: #{e.class} #{e.message}")
    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                alert: "Failed to generate label score: #{e.message.truncate(200)}"
  end

  def regenerate
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label.regenerate

    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                notice: "Label regenerated successfully."
  rescue Faraday::Error
    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                alert: "Failed to regenerate label."
  end

  def approve
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label.approve

    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                notice: "Label approved."
  rescue Faraday::Error
    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                alert: "Failed to approve label."
  end

  def reject
    authorize GoodsNomenclatureLabel, :update?

    @goods_nomenclature_label.reject

    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                notice: "Label marked for review."
  rescue Faraday::Error
    redirect_to goods_nomenclature_label_path(goods_nomenclature_id),
                alert: "Failed to reject label."
  end

private

  def load_label
    @goods_nomenclature_label = find_label(skip_oid: true)
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_labels_path, alert: "Label not found for commodity code #{goods_nomenclature_id}."
  end

  def find_label(skip_oid: false)
    opts = {}
    opts[:oid] = params[:oid] if params[:oid].present? && !skip_oid

    GoodsNomenclatureLabel.find(goods_nomenclature_id, opts)
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
      attrs[:labels]["known_brands"] = GoodsNomenclatureLabel.text_to_array(label_params[:known_brands_text])
    end

    if label_params[:colloquial_terms_text]
      attrs[:labels]["colloquial_terms"] = GoodsNomenclatureLabel.text_to_array(label_params[:colloquial_terms_text])
    end

    if label_params[:synonyms_text]
      attrs[:labels]["synonyms"] = GoodsNomenclatureLabel.text_to_array(label_params[:synonyms_text])
    end

    attrs
  end

  def fetch_versions
    Version.all(item_type: "GoodsNomenclatureLabel", item_id: @goods_nomenclature_label.goods_nomenclature_sid)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def normalize_commodity_code(code)
    code.to_s.gsub(/\s+/, "")
  end

  def valid_commodity_code?(code)
    code.match?(/\A\d{10}\z/)
  end
end
