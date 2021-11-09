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

  def govuk_form_for(*args, **options, &block)
    merged = options.dup
    merged[:builder] = GOVUKDesignSystemFormBuilder::FormBuilder
    merged[:html] ||= {}
    merged[:html][:novalidate] = true

    form_for(*args, **merged, &block)
  end

  def govuk_breadcrumbs(breadcrumbs)
    render GovukComponent::BreadcrumbsComponent.new(breadcrumbs: breadcrumbs)
  end
end
