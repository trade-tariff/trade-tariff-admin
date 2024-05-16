module XiOnly
  extend ActiveSupport::Concern

  included do
    def check_service
      if TradeTariffAdmin::ServiceChooser.uk?
        raise ActionController::RoutingError, 'Invalid service'
      end
    end
  end
end
