# Distribution lists (Cognito dl-* groups): TECHNICAL_OPERATOR only
class DistributionListPolicy < ApplicationPolicy
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
