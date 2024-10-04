module Sortable
  extend ActiveSupport::Concern

  included do
    helper_method :sort_column, :sort_direction
  end

  private

  def sort_column
    params[:sort]
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
