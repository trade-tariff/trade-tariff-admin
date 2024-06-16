module GreenLanes
  class CategoryAssessmentExemption
    include Her::JsonApi::Model
    use_api Her::XI_API

    attributes :category_assessment_id, :exemption_id

    validates :exemption_id, presence: true
    validates :category_assessment_id, presence: true

    def add_exemption
      self.class.post_raw("/admin/green_lanes/category_assessments/#{category_assessment_id}/exemptions", exemption_id:)
    end
  end
end
