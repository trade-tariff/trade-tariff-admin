module GreenLanes
  class Exemption
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :code,
               :description

    collection_path '/admin/green_lanes/exemptions'

    def label
      "#{code} - #{description}"
    end
  end
end
