module GreenLanes
  class Exemption
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :code,
               :description,
               :created_at,
               :updated_at

    collection_path '/admin/green_lanes/exemptions'
  end
end
