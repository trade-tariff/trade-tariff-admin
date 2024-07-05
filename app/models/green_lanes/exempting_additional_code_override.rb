module GreenLanes
  class ExemptingAdditionalCodeOverride
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :additional_code_type_id,
               :additional_code,
               :created_at,
               :updated_at

    collection_path '/admin/green_lanes/exempting_additional_code_overrides'
  end
end
