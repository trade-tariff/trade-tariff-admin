module GreenLanes
  class MeasuresController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @measures = GreenLanes::Measure.all(page: current_page).fetch
    end
  end
end
