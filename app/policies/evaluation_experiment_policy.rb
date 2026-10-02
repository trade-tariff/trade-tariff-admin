class EvaluationExperimentPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def create?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
