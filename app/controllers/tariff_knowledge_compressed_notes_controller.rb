class TariffKnowledgeCompressedNotesController < AuthenticatedController
  before_action :load_compressed_note, only: %i[regenerate approve reject update]

  def index
    authorize TariffKnowledgeCompressedNote, :index?

    respond_to do |format|
      format.html { redirect_to goods_nomenclature_self_texts_path(anchor: "compressed-notes") }
      format.json { render json: TariffKnowledgeCompressedNote.listing(params) }
    end
  end

  def search
    authorize TariffKnowledgeCompressedNote, :index?

    query = search_params[:q].to_s.gsub(/\s+/, " ").strip

    if query.blank?
      redirect_to goods_nomenclature_self_texts_path(anchor: "compressed-notes"), alert: "Please enter a search term."
      return
    end

    redirect_to goods_nomenclature_self_texts_path(anchor: "compressed-notes", q: query)
  end

  def show
    authorize TariffKnowledgeCompressedNote, :show?

    @compressed_note = find_compressed_note
    @versions = fetch_versions
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_self_texts_path(anchor: "compressed-notes"), alert: "Compressed note not found."
  end

  def regenerate
    authorize TariffKnowledgeCompressedNote, :update?

    @compressed_note.regenerate

    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                notice: "Compressed note regenerated successfully."
  rescue Faraday::Error
    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                alert: "Failed to regenerate compressed note."
  end

  def approve
    authorize TariffKnowledgeCompressedNote, :update?

    @compressed_note.approve

    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                notice: "Compressed note approved."
  rescue Faraday::Error
    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                alert: "Failed to approve compressed note."
  end

  def reject
    authorize TariffKnowledgeCompressedNote, :update?

    @compressed_note.reject

    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                notice: "Compressed note marked for review."
  rescue Faraday::Error
    redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                alert: "Failed to reject compressed note."
  end

  def update
    authorize TariffKnowledgeCompressedNote, :update?

    @compressed_note.assign_attributes(content: compressed_note_params[:content])

    if @compressed_note.save && @compressed_note.errors.empty?
      redirect_to tariff_knowledge_compressed_note_path(goods_nomenclature_id),
                  notice: "Compressed note updated successfully."
    else
      @versions = fetch_versions
      render :show, status: :unprocessable_content
    end
  end

private

  def fetch_versions
    Version.all(item_type: "TariffKnowledge::CompressedNote", item_id: @compressed_note.goods_nomenclature_sid)
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def find_compressed_note(skip_oid: false)
    opts = {}
    opts[:oid] = params[:oid] if params[:oid].present? && !skip_oid

    TariffKnowledgeCompressedNote.find(goods_nomenclature_id, opts)
  end

  def load_compressed_note
    @compressed_note = find_compressed_note(skip_oid: true)
  rescue Faraday::ResourceNotFound
    redirect_to goods_nomenclature_self_texts_path(anchor: "compressed-notes"), alert: "Compressed note not found."
  end

  def goods_nomenclature_id
    params[:goods_nomenclature_id]
  end

  def search_params
    params.permit(:q)
  end

  def compressed_note_params
    params.require(:tariff_knowledge_compressed_note).permit(:content)
  end
end
