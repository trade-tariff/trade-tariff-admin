module GreenLanes
  class ExemptingOverridesController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @exempting_certificate_overrides = GreenLanes::ExemptingCertificateOverride.all(page: current_page).fetch
      @exempting_additional_code_overrides = GreenLanes::ExemptingAdditionalCodeOverride.all(page: current_page).fetch
    end
  end
end
