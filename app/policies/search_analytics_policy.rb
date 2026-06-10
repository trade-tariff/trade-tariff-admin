class SearchAnalyticsPolicy < ApplicationPolicy
  def index?
    technical_operator? || hmrc_admin? || auditor?
  end
end
