class EvaluationRunPolicy < ApplicationPolicy
  def create?
    technical_operator?
  end

  def show?
    technical_operator?
  end
end
