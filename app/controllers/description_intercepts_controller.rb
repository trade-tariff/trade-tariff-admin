class DescriptionInterceptsController < AuthenticatedController
  before_action :load_description_intercept, only: %i[show edit update]

  def index
    authorize DescriptionIntercept, :index?

    respond_to do |format|
      format.html
      format.json { render json: DescriptionIntercept.listing(params) }
    end
  end

  def new
    authorize DescriptionIntercept, :update?

    @description_intercept = DescriptionIntercept.new(sources: %w[guided_search])
    load_selected_short_codes
  end

  def create
    authorize DescriptionIntercept, :update?

    @description_intercept = DescriptionIntercept.new(description_intercept_params)

    if @description_intercept.save && @description_intercept.errors.empty?
      redirect_to description_intercept_path(@description_intercept), notice: "Description intercept created successfully."
    else
      load_selected_short_codes
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize DescriptionIntercept, :show?

    @versions = fetch_versions
    load_selected_short_codes
  rescue Faraday::ResourceNotFound
    redirect_to description_intercepts_path, alert: "Description intercept not found."
  end

  def edit
    authorize DescriptionIntercept, :update?
    load_selected_short_codes
  rescue Faraday::ResourceNotFound
    redirect_to description_intercepts_path, alert: "Description intercept not found."
  end

  def update
    authorize DescriptionIntercept, :update?

    @description_intercept.assign_attributes(description_intercept_params)
    clear_hidden_fields_for_update!

    if @description_intercept.save && @description_intercept.errors.empty?
      redirect_to description_intercept_path(@description_intercept), notice: "Description intercept updated successfully."
    else
      @versions = fetch_versions
      load_selected_short_codes
      render :edit, status: :unprocessable_content
    end
  rescue Faraday::ResourceNotFound
    redirect_to description_intercepts_path, alert: "Description intercept not found."
  end

private

  def load_description_intercept
    @description_intercept = DescriptionIntercept.find(params[:id], params[:oid].present? ? { oid: params[:oid] } : {})
  end

  def fetch_versions
    Version.all(item_type: "DescriptionIntercept", item_id: @description_intercept.resource_id)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def load_selected_short_codes
    @selected_short_codes = GoodsNomenclatureAutocompleteResult.selected_listing(@description_intercept.filter_prefixes)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch selected short codes: #{e.message}")
    @selected_short_codes = Array(@description_intercept.filter_prefixes).map do |code|
      { goods_nomenclature_item_id: code, truncated_description: nil }
    end
  end

  def description_intercept_params
    permitted = params.require(:description_intercept).permit(
      :term,
      :excluded,
      :message,
      :escalate_to_webchat,
      sources: [],
      filter_prefixes: [],
    )

    permitted[:excluded] = ActiveModel::Type::Boolean.new.cast(permitted[:excluded]) if permitted.key?(:excluded)
    permitted[:escalate_to_webchat] = ActiveModel::Type::Boolean.new.cast(permitted[:escalate_to_webchat]) if permitted.key?(:escalate_to_webchat)
    permitted[:message] = permitted[:message].presence if permitted.key?(:message)
    permitted[:sources] = Array(permitted[:sources]).reject(&:blank?)
    permitted[:filter_prefixes] = Array(permitted[:filter_prefixes]).reject(&:blank?)

    if permitted[:excluded]
      permitted.delete(:filter_prefixes)
    end

    permitted
  end

  def clear_hidden_fields_for_update!
    return if @description_intercept.blank?

    if @description_intercept.message.blank?
      @description_intercept.guidance_level = nil
      @description_intercept.guidance_location = nil
    else
      @description_intercept.guidance_level = "info"
      @description_intercept.guidance_location = "interstitial"
    end

    @description_intercept.filter_prefixes = [] if @description_intercept.excluded?
  end
end
