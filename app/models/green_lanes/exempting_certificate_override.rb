module GreenLanes
  class ExemptingCertificateOverride
    include ApiEntity

    xi_only

    attr_accessor :certificate_type_code, :certificate_code
  end
end
