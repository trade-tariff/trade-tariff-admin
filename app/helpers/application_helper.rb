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

  def format_role_name(role)
    return "No role" if role.blank?

    # Known acronyms that should stay uppercase
    acronyms = %w[HMRC]

    # Split by underscore and format each word
    role.split("_").map { |word|
      # If word is a known acronym, keep it uppercase
      # Otherwise, capitalize first letter and downcase the rest
      acronyms.include?(word.upcase) ? word.upcase : word.capitalize
    }.join(" ")
  end
end
