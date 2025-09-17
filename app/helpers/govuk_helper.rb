module GovukHelper
  def govuk_breadcrumbs(breadcrumbs)
    render GovukComponent::BreadcrumbsComponent.new(breadcrumbs:)
  end

  def govuk_form_for(*args, **options, &block)
    merged = options.dup
    merged[:builder] = GOVUKDesignSystemFormBuilder::FormBuilder
    merged[:html] ||= {}
    merged[:html][:novalidate] = true

    form_for(*args, **merged) do |form|
      safe_join [
        form.govuk_error_summary,
        capture(form, &block),
      ], "\n"
    end
  end

  def submit_button_label(form)
    name = form.object.class.model_name.human

    form.object.persisted? ? "Update #{name}" : "Create #{name}"
  end

  def submit_and_back_buttons(form, back_link, submit: nil, back_text: "Back")
    submit ||= submit_button_label(form)

    submit_btn = form.govuk_submit(submit)
    back_btn = link_to(back_text, back_link,
                       class: "govuk-button govuk-button--secondary")

    tag.div class: "govuk-button-group" do
      safe_join [submit_btn, back_btn], "\n"
    end
  end

  def govuk_markdown_area(form, field_name, **options)
    render "application/markdown_field",
           form:,
           field_name:,
           field_options: options
  end
end
