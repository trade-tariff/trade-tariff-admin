require "trade_tariff_admin"

module RoutingFilter
  class ServicePathPrefixHandler < Filter
    SERVICE_CHOICE_PREFIXES =
      ::TradeTariffAdmin::ServiceChooser.service_choices
                                           .keys
                                           .map { |prefix| Regexp.escape(prefix) }
                                           .join("|")
                                           .freeze

    SERVICE_CHOICE_PREFIXES_REGEX = %r{^/(#{SERVICE_CHOICE_PREFIXES})(?=/|$)}

    # Recognising paths
    def around_recognize(path, _env)
      service_choice = extract_segment!(SERVICE_CHOICE_PREFIXES_REGEX, path)

      ::TradeTariffAdmin::ServiceChooser.service_choice = service_choice

      yield
    end

    # Rendering links
    def around_generate(_params)
      yield.tap do |result, _params|
        service_choice = ::TradeTariffAdmin::ServiceChooser.service_choice

        if service_choice.present? && service_choice != service_choice_default
          prepend_service_choice(result, service_choice)
        end
      end
    end

  private

    # ResultWrapper#update replaces an in-memory URL; it is not model persistence.
    def prepend_service_choice(result, service_choice)
      result.update(prepend_segment(result.url, service_choice))
    end

    def service_choice_default
      ::TradeTariffAdmin::ServiceChooser.service_default
    end
  end
end
