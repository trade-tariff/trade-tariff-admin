module GreenLanes
  class MeasurePagination
    include Her::JsonApi::Model

    attributes :total_pages, :current_page, :limit_value
  end
end
