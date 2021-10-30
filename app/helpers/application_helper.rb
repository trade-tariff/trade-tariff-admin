module ApplicationHelper
  def nav_link(name, url, activator = '')
    opts = {}
    opts[:class] = 'active' if active_nav_link?(activator)

    tag.li(opts) do
      link_to name, url
    end
  end

  def active_nav_link?(activator)
    (activator.is_a?(String) && request.path.start_with?(activator)) ||
      (activator.is_a?(Regexp) && request.path =~ activator)
  end
end
