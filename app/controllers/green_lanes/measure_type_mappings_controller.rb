module GreenLanes
  class MeasureTypeMappingsController < AuthenticatedController
    include XiOnly

    def index
      @measure_type_mappings = GreenLanes::MeasureTypeMapping.all(page: current_page)
    end

    def new
      @measure_type_mapping = GreenLanes::MeasureTypeMapping.new
      @themes = GreenLanes::Theme.all
    end

    def create
      @measure_type_mapping = GreenLanes::MeasureTypeMapping.new(mtm_params)
      @measure_type_mapping.save

      if @measure_type_mapping.errors.none?
        redirect_to green_lanes_measure_type_mappings_path, notice: 'MeasureTypeMapping created'
      else
        @themes = GreenLanes::Theme.all
        render :new
      end
    end

    def destroy
      @measure_type_mapping = GreenLanes::MeasureTypeMapping.find(params[:id])
      @measure_type_mapping.destroy

      redirect_to green_lanes_measure_type_mappings_path, notice: 'MeasureTypeMapping removed'
    end

    private

    def mtm_params
      params.require(:measure_type_mapping).permit(
        :measure_type_id,
        :theme_id,
      )
    end
  end
end
