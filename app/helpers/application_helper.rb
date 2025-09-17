module ApplicationHelper
  def active_nav_link?(activator)
    (activator.is_a?(String) && request.path.start_with?(activator)) ||
      (activator.is_a?(Regexp) && request.path =~ activator)
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, { sort: column, direction:, page: params[:page], filters: params[:filters] }
  end
end
