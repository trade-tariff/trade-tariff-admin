module XiOnly
  extend ActiveSupport::Concern

  included do
    before_action :check_service, :disable_service_switching!

    def check_service
      if TradeTariffAdmin::ServiceChooser.uk?
        raise ActionController::RoutingError, "Invalid service"
      end
    end
  end
end
