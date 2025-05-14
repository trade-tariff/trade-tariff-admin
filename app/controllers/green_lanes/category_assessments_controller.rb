module GreenLanes
  class CategoryAssessmentsController < AuthenticatedController
    include Sortable
    include XiOnly

    def index
      merge_filters
      @category_assessments = GreenLanes::CategoryAssessment.all(search_params)
      @themes = GreenLanes::Theme.all
    end

    def new
      @category_assessment = GreenLanes::CategoryAssessment.new
      @themes = GreenLanes::Theme.all
    end

    def create
      @category_assessment = GreenLanes::CategoryAssessment.new(ca_params)
      @category_assessment.save

      if @category_assessment.errors.none?
        redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment created'
      else
        @themes = GreenLanes::Theme.all
        render :new
      end
    end

    def edit
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id], page: current_page)
      prepare_edit
    end

    def update
      @category_assessment = GreenLanes::CategoryAssessment.build(ca_params.merge(resource_id: params[:id]))
      @category_assessment.save

      if @category_assessment.errors.none?
        redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment updated'
      else
        prepare_edit
        render :edit
      end
    end

    def add_exemption
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])

      exemption_id = exemptions_params[:exemption_id]
      category_assessment_exemption = GreenLanes::CategoryAssessmentExemption.new(category_assessment_id: @category_assessment.id, exemption_id:)

      if category_assessment_exemption.valid? && category_assessment_exemption.add_exemption
        redirect_to edit_green_lanes_category_assessment_path(id: params[:id]), notice: 'Exemption assigned successfully'
      else
        prepare_edit
        @category_assessment_exemption = category_assessment_exemption
        render :edit
      end
    end

    def remove_exemption
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])

      exemption_id = params[:exemption_id]
      category_assessment_exemption = GreenLanes::CategoryAssessmentExemption.new(category_assessment_id: @category_assessment.id, exemption_id:)

      if category_assessment_exemption.valid? && category_assessment_exemption.remove_exemption
        redirect_to edit_green_lanes_category_assessment_path(id: params[:id]), notice: 'Exemption removed successfully'
      else
        prepare_edit
        @category_assessment_exemption = category_assessment_exemption
        render :edit
      end
    end

    def add_measure
      measure = GreenLanes::Measure.new(measure_params)
      category_assessment_id = measure_params[:category_assessment_id]
      @category_assessment = GreenLanes::CategoryAssessment.find(category_assessment_id)

      if measure.valid?
        begin
          if measure.save
            redirect_to edit_green_lanes_category_assessment_path(id: category_assessment_id), notice: 'Goods Nomenclature assigned successfully'
          else
            prepare_edit
            @measure = measure
            render :edit
          end
        rescue Faraday::ResourceNotFound
          prepare_edit
          @measure = measure
          @measure.errors.add(:goods_nomenclature_item_id, 'Goods Nomenclature is not valid')
          render :edit
        end
      else
        prepare_edit
        @measure = measure
        render :edit
      end
    end

    def destroy
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])
      @category_assessment.destroy

      redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment removed'
    end

    private

    def prepare_edit
      @themes = GreenLanes::Theme.all

      all_exemptions = GreenLanes::Exemption.all
      existing_exemptions = @category_assessment.has_exemptions? ? @category_assessment.exemptions.map(&:code) : []
      @exemptions = all_exemptions.reject { |exemption| existing_exemptions.include?(exemption.code) }

      @category_assessment_exemption = GreenLanes::CategoryAssessmentExemption.new(category_assessment_id: @category_assessment.id)

      @measure = GreenLanes::Measure.new(category_assessment_id: @category_assessment.id)
    end

    def search_params
      {
        query:
          {
            filters: params[:filters].to_h,
            page: current_page,
            sort: params[:sort],
            direction: params[:direction],
          },
      }
    end

    def merge_filter
      filters = params(:filters, {}).permit(:exemption_code).to_h

      if params[:exemption_code].present?
        filters.merge!(exemption_code: params[:exemption_code])
      else
        params[:exemption_code] = params.dig(:filters, :exemption_code)
      end

      params[:filters] = ActionController::Parameters.new(filters).permit(:exemption_code)
    end

    def merge_filters
      filters = params.fetch(:filters, {}).permit(
        :exemption_code,
        :measure_type_id,
        :regulation_id,
        :regulation_role,
        :theme_id,
      ).to_h

      filter_keys = %i[exemption_code measure_type_id regulation_id regulation_role theme_id]
      filter_keys.each { |filter_key| add_filter(filters, params, filter_key) }

      params[:filters] = ActionController::Parameters.new(filters).permit(
        :exemption_code,
        :measure_type_id,
        :regulation_id,
        :regulation_role,
        :theme_id,
      )
    end

    def add_filter(filters, params, filter_key)
      if params[filter_key].present?
        filters.merge!(filter_key => params[filter_key])
      else
        params[filter_key] = params.dig(:filters, filter_key)
      end
    end

    def ca_params
      params.require(:category_assessment).permit(
        :regulation_id,
        :regulation_role,
        :measure_type_id,
        :theme_id,
      )
    end

    def measure_params
      params.require(:measure).permit(
        :category_assessment_id,
        :goods_nomenclature_item_id,
        :productline_suffix,
      )
    end

    def exemptions_params
      params.require(:cae).permit(
        :exemption_id,
      )
    end
  end
end
