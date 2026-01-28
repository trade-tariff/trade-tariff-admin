# UK Service - GoodsNomenclatureLabel: TECHNICAL_OPERATOR and HMRC_ADMIN full control
class GoodsNomenclatureLabelPolicy < ApplicationPolicy
  def index?
    technical_operator? || hmrc_admin?
  end

  def show?
    technical_operator? || hmrc_admin?
  end

  def update?
    technical_operator? || hmrc_admin?
  end
end
