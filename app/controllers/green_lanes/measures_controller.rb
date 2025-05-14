module GreenLanes
  class MeasuresController < AuthenticatedController
    include XiOnly

    def index
      @measures = GreenLanes::Measure.all(page: current_page)
    end

    def destroy
      @measure = GreenLanes::Measure.build(resource_id: params[:id])
      category_assessment_id = params[:category_assessment_id]
      @measure.destroy

      if category_assessment_id.present?
        redirect_to edit_green_lanes_category_assessment_path(id: category_assessment_id), notice: 'Measure removed'
      else
        redirect_to green_lanes_measures_path, notice: 'Measure removed'
      end
    end
  end
end
