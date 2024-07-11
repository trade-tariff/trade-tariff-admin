module GreenLanes
  class CategoryAssessment
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :measure_type_id,
               :regulation_id,
               :regulation_role,
               :theme_id,
               :created_at,
               :updated_at

    has_one :theme
    has_one :measure_pagination, class_name: 'GreenLanes::MeasurePagination'
    has_many :green_lanes_measures, class_name: 'GreenLanes::Measure'
    has_many :exemptions

    collection_path '/admin/green_lanes/category_assessments'

    def initialize(attributes = {})
      super
      @has_measures = attributes[:green_lanes_measures].present?
      @has_exemptions = attributes[:exemptions].present?
    end

    def has_measures?
      @has_measures
    end

    def has_exemptions?
      @has_exemptions
    end
  end
end
