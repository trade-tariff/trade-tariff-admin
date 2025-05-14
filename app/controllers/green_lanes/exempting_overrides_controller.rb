module GreenLanes
  class ExemptingOverridesController < AuthenticatedController
    include XiOnly

    def index
      @exempting_certificate_overrides = GreenLanes::ExemptingCertificateOverride.all(page: current_page)
      @exempting_additional_code_overrides = GreenLanes::ExemptingAdditionalCodeOverride.all(page: current_page)
    end
  end
end
