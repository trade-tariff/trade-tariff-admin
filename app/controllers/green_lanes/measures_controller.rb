module GreenLanes
  class MeasuresController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @measures = GreenLanes::Measure.all(page: current_page).fetch
    end

    def destroy
      @measure = GreenLanes::Measure.find(params[:id])
      category_assessment_id = params[:category_assessment_id]
      @measure.destroy

      if category_assessment_id.present?
        redirect_to edit_green_lanes_category_assessment_path(id: category_assessment_id), notice: 'Goods Nomenclature removed successfully'
      else
        redirect_to green_lanes_measures_path, notice: 'Measure removed'
      end
    end
  end
end
