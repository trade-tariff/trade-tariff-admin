# UK Service - GoodsNomenclatureSelfText: TECHNICAL_OPERATOR only
class GoodsNomenclatureSelfTextPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def update?
    technical_operator?
  end
end
