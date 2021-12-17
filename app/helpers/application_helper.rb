module ApplicationHelper
  def active_nav_link?(activator)
    (activator.is_a?(String) && request.path.start_with?(activator)) ||
      (activator.is_a?(Regexp) && request.path =~ activator)
  end
end
