RSpec.describe "application/_sub_navigation" do
  let(:section) do
    NavigationHelper::NavigationSection.new(
      key: :nested,
      label: "Evaluation",
      href: "/tariff_knowledge_synthetic_atars",
      service: :uk,
      items: [
        NavigationHelper::NavigationItem.new(
          text: "Synthetic ATaRs",
          href: "/tariff_knowledge_synthetic_atars",
          policy_class: TariffKnowledgeSyntheticAtar,
          active_when: %r{/tariff_knowledge_synthetic_atars},
          service: :uk,
        ),
        NavigationHelper::NavigationItem.new(
          text: "Gold Query Sets",
          href: "/evaluation_gold_query_sets",
          policy_class: EvaluationGoldQuerySet,
          active_when: %r{/evaluation_gold_query_sets},
          service: :uk,
        ),
      ],
    )
  end

  before do
    allow(view).to receive(:request).and_return(instance_double(ActionDispatch::Request, path: "/tariff_knowledge_synthetic_atars"))
  end

  it "renders the current nested tab", :aggregate_failures do
    render partial: "application/sub_navigation", locals: { section: }

    expect(rendered).to include('aria-label="Evaluation"')
    expect(rendered).to include('class="app-sub-navigation"')
    expect(rendered).to include('aria-current="page"')
    expect(rendered).to include("Gold Query Sets")
  end
end
