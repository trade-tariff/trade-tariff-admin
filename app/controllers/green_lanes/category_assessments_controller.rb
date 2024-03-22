module GreenLanes
  class CategoryAssessmentsController < AuthenticatedController
    def index
      @category_assessments = GreenLanes::CategoryAssessment.all(page: current_page).fetch
    end
  end
end
