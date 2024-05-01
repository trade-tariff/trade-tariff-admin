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

    collection_path '/admin/green_lanes/category_assessments'
  end
end
