module GreenLanes
  class CategoryAssessment
    include ApiEntity

    xi_only

    attributes :measure_type_id,
               :regulation_id,
               :regulation_role,
               :theme_id

    has_one :theme
    has_one :measure_pagination, class_name: "GreenLanes::MeasurePagination"
    has_many :green_lanes_measures, class_name: "GreenLanes::Measure"
    has_many :exemptions

    def has_measures?
      self[:green_lanes_measures].present?
    end

    def has_exemptions?
      self[:exemptions].present?
    end
  end
end
