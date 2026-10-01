class EvaluationGoldQueryItemPolicy < ApplicationPolicy
  def update?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
