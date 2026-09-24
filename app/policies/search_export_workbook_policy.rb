class SearchExportWorkbookPolicy < ApplicationPolicy
  def create?
    SearchAnalyticsPolicy.new(user, SearchAnalytics).index?
  end

  alias_method :show?, :create?
  alias_method :download?, :create?
end
