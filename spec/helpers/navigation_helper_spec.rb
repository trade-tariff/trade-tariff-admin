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
    it "returns all four sections" do
      expect(helper.navigation_sections.map(&:key)).to eq(%i[ott_admin classification spimm manage_users])
    end

    it "defines OTT Admin with 6 items" do
      section = helper.navigation_sections.find { |s| s.key == :ott_admin }
      expect(section.items.map(&:text)).to eq(
        ["Section & chapter notes", "News", "Live Issues", "Quotas", "Updates", "Rollbacks"],
      )
    end

    it "defines Classification with 2 items" do
      section = helper.navigation_sections.find { |s| s.key == :classification }
      expect(section.items.map(&:text)).to eq(["Search References", "Labels"])
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
  end

  describe "#visible_navigation_sections" do
    context "with UK service and technical_operator" do
      include_context "with UK service"

      let(:user) { build(:user, :technical_operator) }

      it "shows OTT Admin, Classification, and Manage Users" do
        expect(helper.visible_navigation_sections.map(&:key)).to eq(%i[ott_admin classification manage_users])
      end

      it "hides SPIMM" do
        expect(helper.visible_navigation_sections.map(&:key)).not_to include(:spimm)
      end

      it "includes all 6 OTT Admin items on UK" do
        section = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
        expect(section.items.map(&:text)).to eq(
          ["Section & chapter notes", "News", "Live Issues", "Quotas", "Updates", "Rollbacks"],
        )
      end

      it "includes both Classification items on UK" do
        section = helper.visible_navigation_sections.find { |s| s.key == :classification }
        expect(section.items.map(&:text)).to eq(["Search References", "Labels"])
      end
    end

    context "with XI service and technical_operator" do
      include_context "with XI service"

      let(:user) { build(:user, :technical_operator) }

      it "shows OTT Admin, Classification, SPIMM, and Manage Users" do
        expect(helper.visible_navigation_sections.map(&:key)).to eq(%i[ott_admin classification spimm manage_users])
      end

      it "hides UK-only items from OTT Admin" do
        section = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
        expect(section.items.map(&:text)).to eq(["Section & chapter notes", "Updates", "Rollbacks"])
      end

      it "hides Labels from Classification on XI" do
        section = helper.visible_navigation_sections.find { |s| s.key == :classification }
        expect(section.items.map(&:text)).to eq(["Search References"])
      end

      it "shows all 6 SPIMM items" do
        section = helper.visible_navigation_sections.find { |s| s.key == :spimm }
        expect(section.items.map(&:text)).to contain_exactly(
          "Category Assessments", "Exemptions", "Measures",
          "Exempting Overrides", "Update Notifications", "Measure Type Mappings"
        )
      end
    end

    context "with UK service and hmrc_admin" do
      include_context "with UK service"

      let(:user) { build(:user, :hmrc_admin) }

      it "shows Classification" do
        expect(helper.visible_navigation_sections.map(&:key)).to include(:classification)
      end

      it "hides Manage Users" do
        expect(helper.visible_navigation_sections.map(&:key)).not_to include(:manage_users)
      end

      it "shows OTT Admin with News visible" do
        ott = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
        expect(ott.items.map(&:text)).to include("News")
      end

      it "hides Section & chapter notes from OTT Admin" do
        ott = helper.visible_navigation_sections.find { |s| s.key == :ott_admin }
        expect(ott.items.map(&:text)).not_to include("Section & chapter notes")
      end

      it "includes Search References in Classification" do
        section = helper.visible_navigation_sections.find { |s| s.key == :classification }
        expect(section.items.map(&:text)).to include("Search References")
      end
    end

    context "with UK service and guest" do
      include_context "with UK service"

      let(:user) { build(:user, :guest) }

      it "shows no sections" do
        expect(helper.visible_navigation_sections).to be_empty
      end
    end
  end

  describe "#current_navigation_section" do
    include_context "with UK service"

    let(:user) { build(:user, :technical_operator) }

    context "when on the notes page" do
      let(:request_path) { "/notes/1" }

      it "returns OTT Admin section" do
        expect(helper.current_navigation_section.key).to eq(:ott_admin)
      end
    end

    context "when on the search references page" do
      let(:request_path) { "/search_references" }

      it "returns Classification section" do
        expect(helper.current_navigation_section.key).to eq(:classification)
      end
    end

    context "when on the users page" do
      let(:request_path) { "/users" }

      it "returns Manage Users section" do
        expect(helper.current_navigation_section.key).to eq(:manage_users)
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
  end

  describe "#section_active?" do
    include_context "with UK service"

    let(:user) { build(:user, :technical_operator) }
    let(:request_path) { "/tariff_updates" }

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
      expect(helper.section_href(section)).to eq(helper.root_path)
    end

    it "returns standalone href for Manage Users" do
      section = helper.visible_navigation_sections.find { |s| s.key == :manage_users }
      expect(helper.section_href(section)).to eq(helper.users_path)
    end
  end
end
