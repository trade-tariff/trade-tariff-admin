module GreenLanes
  class MeasureTypeMapping
    include ApiEntity

    attr_accessor :measure_type_id,
                  :theme_id

    has_one :theme

    def label
      theme_id
    end
  end
end
