module GreenLanes
  class ExemptingCertificateOverride
    include ApiEntity

    attr_accessor :certificate_type_code,
                  :certificate_code,
                  :created_at,
                  :updated_at

    set_collection_path '/admin/green_lanes/exempting_certificate_overrides'
  end
end
