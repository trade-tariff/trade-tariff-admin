RSpec.describe SectionNote do
  describe "#preview" do
    subject(:preview) { section_note.preview(:content, linkify_code_references: true) }

    let(:section_note) { described_class.new(content: "Chapter 01 and 0101") }
    let(:page) { Capybara.string(preview) }

    it "links code references when enabled" do
      expect(page).to have_link "Chapter 01", href: "#{TradeTariffAdmin.frontend_host}/search?q=01"
    end
  end
end
