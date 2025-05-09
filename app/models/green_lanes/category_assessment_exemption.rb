module GreenLanes
  class CategoryAssessmentExemption
    include ApiEntity

    attr_accessor :category_assessment_id, :exemption_id

    validates :exemption_id, presence: { message: 'Exemption cannot be blank' }
    validates :category_assessment_id, presence: true

    def add_exemption
      self.class.post_raw("/admin/green_lanes/category_assessments/#{category_assessment_id}/exemptions", exemption_id:)
    end

    def remove_exemption
      self.class.delete_raw("/admin/green_lanes/category_assessments/#{category_assessment_id}/exemptions", exemption_id:)
    end
  end
end
