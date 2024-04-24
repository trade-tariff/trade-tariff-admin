module GreenLanes
  class CategoryAssessmentsController < AuthenticatedController
    before_action :disable_service_switching!
    before_action :check_service
    def index
      @category_assessments = GreenLanes::CategoryAssessment.all(page: current_page).fetch
    end

    def new
      @category_assessment = GreenLanes::CategoryAssessment.new
      @themes = GreenLanes::Theme.all.fetch
    end

    def create
      @category_assessment = GreenLanes::CategoryAssessment.new(ca_params)

      if @category_assessment.valid? && @category_assessment.save
        redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment created'
      else
        @themes = GreenLanes::Theme.all.fetch
        render :new
      end
    end

    def edit
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])
      @themes = GreenLanes::Theme.all.fetch
    end

    def update
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])
      @category_assessment.attributes = ca_params

      if @category_assessment.valid? && @category_assessment.save
        redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment updated'
      else
        @themes = GreenLanes::Theme.all.fetch
        render :edit
      end
    end

    def destroy
      @category_assessment = GreenLanes::CategoryAssessment.find(params[:id])
      @category_assessment.destroy

      redirect_to green_lanes_category_assessments_path, notice: 'Category Assessment removed'
    end

    private

    def ca_params
      params.require(:category_assessment).permit(
        :regulation_id,
        :regulation_role,
        :measure_type_id,
        :theme_id,
      )
    end

    def check_service
      if TradeTariffAdmin::ServiceChooser.uk?
        raise ActionController::RoutingError, 'Invalid service'
      end
    end
  end
end
