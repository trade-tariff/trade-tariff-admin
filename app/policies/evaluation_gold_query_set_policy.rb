class EvaluationGoldQuerySetPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def create?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
