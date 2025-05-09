module GreenLanes
  class Exemption
    include ApiEntity

    attr_accessor :code,
                  :description

    set_collection_path '/admin/green_lanes/exemptions'

    def label
      "#{code} - #{description}"
    end
  end
end
