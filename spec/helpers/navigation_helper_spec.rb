RSpec.describe NavigationHelper, type: :helper do
  let(:user) { build(:user, :technical_operator) }
  let(:request_path) { "/" }
  let(:mock_request) { instance_double(ActionDispatch::Request, path: request_path) }

  before do
    allow(helper).to receive_messages(current_user: user, request: mock_request)
    # Make Pundit's policy helper available (normally provided by controller)
    u = user
    helper.define_singleton_method(:policy) do |record|
      Pundit.policy(u, record)
    end
  end

  describe "#navigation_sections" do
    it "returns all six sections" do
      expect(helper.navigation_sections.map(&:key)).to eq(%i[ott_admin classification evaluation spimm manage_users configuration])
    end

    it "defines OTT Admin with 8 items" do
      section = helper.navigation_sections.find { |s| s.key == :ott_admin }
      expect(section.items.map(&:text)).to eq(
        ["Customs Tariff Updates", "Section & chapter notes", "News", "Live Issues", "Quotas", "Updates", "Reports", "Rollbacks"],
      )
    end

    it "defines Classification with 6 items" do
      section = helper.navigation_sections.find { |s| s.key == :classification }
      expect(section.items.map(&:text)).to eq(["Search References", "Descriptions", "Intercepts", "Search dashboard", "Search diagnostics", "Recent changes"])
    end

    it "subdivides Search References into Browse and Search" do
      item = helper.navigation_sections.find { |s| s.key == :classification }.items.find { |entry| entry.text == "Search References" }

      expect(item.tabs.map(&:text)).to eq(%w[Browse Search])
    end

    it "restricts Evaluation to the UK service" do
      section = helper.navigation_sections.find { |s| s.key == :evaluation }

      expect(section.service).to eq(:uk)
    end

    it "defines Evaluation with the three evaluation tools" do
      section = helper.navigation_sections.find { |s| s.key == :evaluation }

      expect(section.items.map(&:text)).to eq(["Synthetic ATaRs", "Gold Query Sets", "Evaluations"])
    end

    it "defines SPIMM with xi service restriction" do
      section = helper.navigation_sections.find { |s| s.key == :spimm }
      expect(section.service).to eq(:xi)
    end

    it "defines SPIMM with 6 items" do
      section = helper.navigation_sections.find { |s| s.key == :spimm }
      expect(section.items.length).to eq(6)
    end

    it "defines Manage Users as standalone with no items" do
      section = helper.navigation_sections.find { |s| s.key == :manage_users }
      expect(section.items).to be_empty
    end

    it "defines Manage Users with users_path href" do
      section = helper.navigation_sections.find { |s| s.key == :manage_users }
      expect(section.href).to eq(helper.users_path)
    end

    it "defines Configuration as standalone with configurations_path href", :aggregate_failures do
      section = helper.navigation_sections.find { |s| s.key == :configuration }

      expect(section.items).to be_empty
      expect(section.href).to eq(helper.configurations_path)
    end
  end

  describe "#visible_navigation_sections" do
    shared_examples "visible sections and items" do |expected|
      it "shows the correct sections" do
        expect(helper.visible_navigation_sections.map(&:key)).to eq(expected.keys)
      end

      expected.each do |section_key, items|
        next if items.nil? # standalone section, no items to check

        it "shows #{items.any? ? items.join(', ') : 'no items'} in #{section_key}" do
          section = helper.visible_navigation_sections.find { |s| s.key == section_key }
          expect(section.items.map(&:text)).to eq(items)
        end
      end
    end

    context "with UK service and technical_operator role" do
      include_context "with UK service"

      let(:user) { build(:user, :technical_operator) }

      include_examples "visible sections and items",
                       ott_admin: [
                         "Customs Tariff Updates",
                         "News",
                         "Live Issues",
                         "Quotas",
                         "Updates",
                         "Reports",
                         "Rollbacks",
                       ],
                       classification: ["Search References", "Descriptions", "Intercepts", "Search dashboard", "Search diagnostics", "Recent changes"],
                       evaluation: ["Synthetic ATaRs", "Gold Query Sets", "Evaluations"],
                       manage_users: nil,
                       configuration: []
    end

    context "with UK service when synthetic ATaRs are hidden" do
      include_context "with UK service"

      let(:user) { build(:user, :technical_operator) }
      let(:evaluation_section) do
        helper.visible_navigation_sections.find { |section| section.key == :evaluation }
      end

      before do
        allow(Pundit).to receive(:policy).and_wrap_original do |method, policy_user, record|
          if record == TariffKnowledgeSyntheticAtar
            instance_double(TariffKnowledgeSyntheticAtarPolicy, index?: false)
          else
            method.call(policy_user, record)
          end
        end
      end

      it "keeps the other evaluation items" do
        expect(evaluation_section.items.map(&:text)).to eq(["Gold Query Sets", "Evaluations"])
      end

      it "links Evaluation to the first visible item" do
        expect(helper.section_href(evaluation_section)).to eq(helper.evaluation_gold_query_sets_path)
      end
    end

    context "with UK service and hmrc_admin role" do
      include_context "with UK service"

      let(:user) { build(:user, :hmrc_admin) }

      include_examples "visible sections and items",
                       ott_admin: ["News", "Live Issues"],
                       classification: ["Search References", "Search dashboard", "Search diagnostics"]
    end

    context "with UK service and auditor role" do
      include_context "with UK service"

      let(:user) { build(:user, :auditor) }

      include_examples "visible sections and items",
                       ott_admin: [
                         "Customs Tariff Updates",
                         "News",
                         "Live Issues",
                         "Quotas",
                         "Updates",
                         "Rollbacks",
                       ],
                       classification: ["Search References", "Search dashboard", "Search diagnostics"],
                       configuration: []
    end

    context "with UK service and guest role" do
      include_context "with UK service"

      let(:user) { build(:user, :guest) }

      it "shows no sections" do
        expect(helper.visible_navigation_sections).to be_empty
      end
    end

    context "with XI service and technical_operator role" do
      include_context "with XI service"

      let(:user) { build(:user, :technical_operator) }

      include_examples "visible sections and items",
                       ott_admin: ["Section & chapter notes", "Updates", "Reports", "Rollbacks"],
                       classification: ["Search References", "Descriptions", "Search dashboard", "Search diagnostics", "Recent changes"],
                       spimm: [
                         "Category Assessments",
                         "Exemptions",
                         "Measures",
                         "Exempting Overrides",
                         "Update Notifications",
                         "Measure Type Mappings",
                       ],
                       manage_users: nil
    end

    context "with XI service and hmrc_admin role" do
      include_context "with XI service"

      let(:user) { build(:user, :hmrc_admin) }

      include_examples "visible sections and items",
                       classification: ["Search References", "Search dashboard", "Search diagnostics"]
    end

    context "with XI service and auditor role" do
      include_context "with XI service"

      let(:user) { build(:user, :auditor) }

      include_examples "visible sections and items",
                       ott_admin: ["Section & chapter notes", "Updates", "Rollbacks"],
                       classification: ["Search References", "Search dashboard", "Search diagnostics"],
                       spimm: [
                         "Category Assessments",
                         "Exemptions",
                         "Measures",
                         "Exempting Overrides",
                         "Update Notifications",
                         "Measure Type Mappings",
                       ]
    end

    context "with XI service and guest role" do
      include_context "with XI service"

      let(:user) { build(:user, :guest) }

      it "shows no sections" do
        expect(helper.visible_navigation_sections).to be_empty
      end
    end
  end

  describe "#current_navigation_section" do
    include_context "with UK service"

    let(:user) { build(:user, :technical_operator) }

    context "when on the customs tariff page" do
      let(:request_path) { "/customs_tariff/updates" }

      it "returns OTT Admin section" do
        expect(helper.current_navigation_section.key).to eq(:ott_admin)
      end
    end

    context "when on the search references page" do
      let(:request_path) { "/search_references" }

      it "returns Classification section" do
        expect(helper.current_navigation_section.key).to eq(:classification)
      end

      it "subdivides Search References and marks Browse current", :aggregate_failures do
        tabs = helper.current_navigation_tabs_section

        expect(tabs.label).to eq("Search References")
        expect(tabs.items.map(&:text)).to eq(%w[Browse Search])
        expect(helper.item_active?(tabs.items[0])).to be true
        expect(helper.item_active?(tabs.items[1])).to be false
      end
    end

    context "when on the search references search page" do
      let(:request_path) { "/search_references/search" }

      it "marks Search current and leaves Browse inactive", :aggregate_failures do
        tabs = helper.current_navigation_tabs_section

        expect(helper.item_active?(tabs.items[0])).to be false
        expect(helper.item_active?(tabs.items[1])).to be true
      end
    end

    context "when on a synthetic ATaR page" do
      let(:request_path) { "/tariff_knowledge_synthetic_atars/12/edit" }

      it "returns the Evaluation section" do
        expect(helper.current_navigation_section.key).to eq(:evaluation)
      end

      it "marks Synthetic ATaRs current" do
        items = helper.current_navigation_section.items

        expect(items.map { |item| helper.item_active?(item) }).to eq([true, false, false])
      end
    end

    context "when on a gold query item page" do
      let(:request_path) { "/evaluation_gold_query_sets/3/items/atar-1/edit" }

      it "marks Gold Query Sets current" do
        item = helper.current_navigation_section.items.find { |entry| entry.text == "Gold Query Sets" }

        expect(helper.item_active?(item)).to be true
      end
    end

    context "when on an evaluation run page" do
      let(:request_path) { "/evaluation_runs/9/results/4" }

      it "marks Evaluations current" do
        items = helper.current_navigation_section.items
        active = items.map { |item| [item.text, helper.item_active?(item)] }.to_h

        expect(active).to include("Evaluations" => true, "Synthetic ATaRs" => false)
      end
    end

    context "when on descriptions" do
      let(:request_path) { "/goods_nomenclature_self_texts" }

      it "does not show a further subdivision" do
        expect(helper.current_navigation_tabs_section).to be_nil
      end
    end

    context "when on the users page" do
      let(:request_path) { "/users" }

      it "returns Manage Users section" do
        expect(helper.current_navigation_section.key).to eq(:manage_users)
      end
    end

    context "when on the configurations page" do
      let(:request_path) { "/configurations" }

      it "returns Configuration section" do
        expect(helper.current_navigation_section.key).to eq(:configuration)
      end
    end

    context "when on a non-matching path" do
      let(:request_path) { "/some/unknown/path" }

      it "returns nil" do
        expect(helper.current_navigation_section).to be_nil
      end
    end
  end

  describe "#current_navigation_section on XI" do
    include_context "with XI service"

    let(:user) { build(:user, :technical_operator) }

    context "when on category assessments page" do
      let(:request_path) { "/category_assessments" }

      it "returns SPIMM section" do
        expect(helper.current_navigation_section.key).to eq(:spimm)
      end
    end

    context "when on XI root path" do
      let(:request_path) { "/xi" }

      it "returns nil (landing page has no active section)" do
        expect(helper.current_navigation_section).to be_nil
      end
    end

    context "when on XI root path with trailing slash" do
      let(:request_path) { "/xi/" }

      it "returns nil (landing page has no active section)" do
        expect(helper.current_navigation_section).to be_nil
      end
    end
  end

  describe "#section_active?" do
    include_context "with UK service"

    let(:user) { build(:user, :technical_operator) }
    let(:request_path) { "/customs_tariff/updates" }

    it "returns true for OTT Admin when path matches" do
      section = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
      expect(helper.section_active?(section)).to be true
    end

    it "returns false for Classification when path does not match" do
      section = helper.visible_navigation_sections.find { |s| s.key == :classification }
      expect(helper.section_active?(section)).to be false
    end
  end

  describe "#section_href" do
    include_context "with UK service"

    let(:user) { build(:user, :technical_operator) }

    it "returns first item href for sections with items" do
      section = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
      expect(helper.section_href(section)).to eq(helper.customs_tariff_updates_path)
    end

    it "returns standalone href for Manage Users" do
      section = helper.visible_navigation_sections.find { |s| s.key == :manage_users }
      expect(helper.section_href(section)).to eq(helper.users_path)
    end
  end
end
