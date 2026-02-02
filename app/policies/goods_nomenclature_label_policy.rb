# UK Service - GoodsNomenclatureLabel: TECHNICAL_OPERATOR only
class GoodsNomenclatureLabelPolicy < ApplicationPolicy
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
