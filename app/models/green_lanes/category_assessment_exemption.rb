module GreenLanes
  class CategoryAssessmentExemption
    include ApiEntity

    xi_only

    attributes :category_assessment_id, :exemption_id

    validates :exemption_id, presence: true
    validates :category_assessment_id, presence: true

    def add_exemption
      api.post("/admin/green_lanes/category_assessments/#{category_assessment_id}/exemptions", exemption_id:)
    end

    def remove_exemption
      api.delete("/admin/green_lanes/category_assessments/#{category_assessment_id}/exemptions", exemption_id:)
    end
  end
end
