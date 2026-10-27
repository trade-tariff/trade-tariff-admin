RSpec.describe EvaluationSourcesHelper do
  def source_html(attributes)
    Capybara.string(helper.evaluation_source(EvaluationExperiment.new(attributes)))
  end

  it "links a gold query set by name to its page and says it is a gold query set", :aggregate_failures do
    html = source_html("source_type" => "gold_query_set", "source_name" => "Baseline GQS", "gold_query_set_id" => 3)

    expect(html).to have_link("Baseline GQS", href: helper.evaluation_gold_query_set_path(3))
    expect(html).to have_text("Gold query set")
  end

  it "links a synthetic input set by name to its page and says it is a synthetic input set", :aggregate_failures do
    html = source_html("source_type" => "synthetic_input_set", "source_name" => "Baseline SIS", "synthetic_input_set_id" => 9)

    expect(html).to have_link("Baseline SIS", href: helper.evaluation_synthetic_input_set_path(9))
    expect(html).to have_text("Synthetic input set")
  end

  it "says no set has been chosen when there is none", :aggregate_failures do
    html = source_html("name" => "Baseline")

    expect(html).to have_text("None chosen")
    expect(html).not_to have_link
  end

  it "does not let a set's name inject markup", :aggregate_failures do
    html = source_html("source_type" => "gold_query_set", "source_name" => "<script>alert(1)</script>", "gold_query_set_id" => 3)

    expect(html).not_to have_css("script")
    expect(html).to have_link("<script>alert(1)</script>")
  end
end
