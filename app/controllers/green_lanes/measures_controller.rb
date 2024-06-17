module GreenLanes
  class MeasuresController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @measures = GreenLanes::Measure.all(page: current_page).fetch
    end

    def create
      measures = GreenLanes::Measure.new(measure_params)
      category_assessment_id = measure_params[:category_assessment_id]

      unless measures.valid? && measures.save
        session[:measures_errors] = measures.errors.full_messages
      end

      redirect_to edit_green_lanes_category_assessment_path(id: category_assessment_id), notice: 'Goods Nomenclature assigned successfully'
    end

    def destroy
      @measure = GreenLanes::Measure.find(params[:id])
      category_assessment_id = @measure.category_assessment.id
      @measure.destroy

      redirect_to edit_green_lanes_category_assessment_path(id: category_assessment_id), notice: 'Goods Nomenclature removed successfully'
    end

    def measure_params
      params.require(:measure).permit(
        :category_assessment_id,
        :goods_nomenclature_item_id,
        :productline_suffix,
      )
    end
  end
end
