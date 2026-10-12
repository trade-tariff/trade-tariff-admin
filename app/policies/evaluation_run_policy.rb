class EvaluationRunPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def create?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def compare?
    technical_operator?
  end
end
