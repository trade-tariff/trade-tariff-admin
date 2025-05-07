module GreenLanes
  class Exemption
    include ApiEntity

    attr_accessor :code,
                  :description

    def label
      "#{code} - #{description}"
    end
  end
end
