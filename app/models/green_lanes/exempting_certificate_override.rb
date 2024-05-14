module GreenLanes
  class ExemptingCertificateOverride
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :certificate_type_code,
               :certificate_code,
               :created_at,
               :updated_at

    collection_path '/admin/green_lanes/exempting_certificate_overrides'
  end
end
