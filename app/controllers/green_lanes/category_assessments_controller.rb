module GreenLanes
  class CategoryAssessmentsController < AuthenticatedController
    before_action :check_service
    def index
      @category_assessments = GreenLanes::CategoryAssessment.all(page: current_page).fetch
    end

    private
    def check_service
      if TradeTariffAdmin::ServiceChooser.uk?
        raise ActionController::RoutingError, 'Invalid service'
      end
    end

  end
end
