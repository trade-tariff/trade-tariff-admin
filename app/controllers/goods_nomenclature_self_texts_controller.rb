class GoodsNomenclatureSelfTextsController < AuthenticatedController
  before_action :load_self_text, only: %i[score regenerate approve reject update]

  def index
    authorize GoodsNomenclatureSelfText, :index?

    respond_to do |format|
      format.html
      format.json { render json: GoodsNomenclatureSelfText.listing(params) }
    end
  end

  def search
    authorize GoodsNomenclatureSelfText, :index?

    query = search_params[:q].to_s.gsub(/\s+/, " ").strip

    if query.blank?
      redirect_to goods_nomenclature_self_texts_path, alert: "Please enter a search term."
      return
    end

    if query.length < 2
      redirect_to goods_nomenclature_self_texts_path, alert: "Search must be at least 2 characters."
      return
    end

    redirect_to goods_nomenclature_self_texts_path(q: query)
  end

  def show
    authorize GoodsNomenclatureSelfText, :show?

    @self_text = find_self_text
    @versions = fetch_versions
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_self_texts_path, alert: "Self-text not found."
  end

  def score
    authorize GoodsNomenclatureSelfText, :update?

    @self_text.generate_score

    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                notice: "Score generated successfully."
  rescue Faraday::Error => e
    Rails.logger.error("Failed to generate score for #{goods_nomenclature_id}: #{e.class} #{e.message}")
    redirect_to goods_nomenclature_self_text_path(goods_nomenclature_id),
                alert: "Failed to generate score: #{e.message.truncate(200)}"
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
      @versions = fetch_versions
      render :show, status: :unprocessable_content
    end
  end

private

  def fetch_versions
    Version.all(item_type: "GoodsNomenclatureSelfText", item_id: @self_text.goods_nomenclature_sid)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def find_self_text
    opts = {}
    opts[:oid] = params[:oid] if params[:oid].present?

    GoodsNomenclatureSelfText.find(goods_nomenclature_id, opts)
  end

  def load_self_text
    @self_text = GoodsNomenclatureSelfText.find(goods_nomenclature_id)
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_self_texts_path, alert: "Self-text not found."
  end

  def goods_nomenclature_id
    params[:goods_nomenclature_id]
  end

  def search_params
    params.permit(:q)
  end

  def self_text_params
    params.require(:goods_nomenclature_self_text).permit(:self_text)
  end
end
