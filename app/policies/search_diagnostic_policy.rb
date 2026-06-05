class SearchDiagnosticPolicy < ApplicationPolicy
  def index?
    technical_operator? || hmrc_admin? || auditor?
  end

  def show?
    index?
  end
end
