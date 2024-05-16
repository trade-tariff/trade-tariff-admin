module GreenLanes
  class ExemptionsController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @exemptions = GreenLanes::Exemption.all.fetch
    end
  end
end
