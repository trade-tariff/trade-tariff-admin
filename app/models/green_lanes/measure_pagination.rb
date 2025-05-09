module GreenLanes
  class MeasurePagination
    include ApiEntity

    attr_accessor :total_pages, :current_page, :limit_value
  end
end
