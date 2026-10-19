class EvaluationSyntheticInputSetPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def create?
    technical_operator?
  end
end
