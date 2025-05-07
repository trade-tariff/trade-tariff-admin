module GreenLanes
  class ExemptingAdditionalCodeOverride
    include ApiEntity

    attr_accessor :additional_code_type_id,
                  :additional_code,
                  :created_at,
                  :updated_at

    set_collection_path '/admin/green_lanes/exempting_additional_code_overrides'
  end
end
