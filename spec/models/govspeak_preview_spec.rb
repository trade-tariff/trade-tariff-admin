RSpec.describe GovspeakPreview do
  subject(:preview) { described_class.new content }

  let :content do
    <<~EOCONTENT
      # Heading

      This is content for [[SERVICE_NAME]]

      This is a <a href="/" target="_blank">link</a>
    EOCONTENT
  end

  describe "#render" do
    subject(:rendered) { preview.render }

    include_context "with UK service"

    it "converts markdown" do
      expect(rendered).to match '<h1 id="heading">Heading</h1>'
    end

    it "replaces service tags" do
      expect(rendered).to match "content for UK"
    end

    it "supports links to new windows" do
      expect(rendered).to match '<a href="/" target="_blank">link</a>'
    end

    context "when code reference linkification is enabled" do
      subject(:preview) { described_class.new content, linkify_code_references: true }

      let(:content) { "Chapter 01, 0101, 010121, 01012100 and 0101210000" }
      let(:page) { Capybara.string(rendered) }

      it "links chapter references to frontend search" do
        expect(page).to have_link "Chapter 01", href: "#{TradeTariffAdmin.frontend_host}/search?q=01"
      end

      it "links heading references to frontend search" do
        expect(page).to have_link "0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101"
      end

      it "renders heading links with the GOV.UK link class" do
        link = page.find_link("0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101")

        expect(link[:class]).to include("govuk-link")
      end

      it "renders heading links with new tab attributes" do
        link = page.find_link("0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101")

        expect(link[:target]).to eq("_blank")
      end

      it "renders heading links with reverse tabnabbing protection" do
        link = page.find_link("0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101")

        expect(link[:rel]).to eq("noreferrer noopener")
      end

      it "adds visually hidden new tab text to heading links" do
        link = page.find_link("0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101")

        expect(link).to have_css(".govuk-visually-hidden", text: "(opens in new tab)", visible: :all)
      end

      it "links subheading references to frontend search" do
        expect(page).to have_link "010121", href: "#{TradeTariffAdmin.frontend_host}/search?q=010121"
      end

      it "links 8 digit commodity references to frontend search" do
        expect(page).to have_link "01012100", href: "#{TradeTariffAdmin.frontend_host}/search?q=01012100"
      end

      it "links 10 digit commodity references to frontend search" do
        expect(page).to have_link "0101210000", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101210000"
      end
    end

    context "when code reference linkification is enabled for a list item starting with a heading" do
      subject(:preview) { described_class.new content, linkify_code_references: true }

      let(:content) { "- 0101 is specific to horses" }
      let(:page) { Capybara.string(rendered) }

      it "links the heading reference" do
        expect(page).to have_link "0101", href: "#{TradeTariffAdmin.frontend_host}/search?q=0101"
      end
    end

    context "when code reference linkification is enabled for a 4 digit quantity followed by a unit" do
      subject(:preview) { described_class.new content, linkify_code_references: true }

      let(:content) { "- cylinder capacity <= 1000 cm3" }
      let(:page) { Capybara.string(rendered) }

      it "does not link the quantity" do
        expect(page).to have_no_link "1000"
      end
    end

    context "when code reference linkification is enabled for content with an existing markdown link" do
      subject(:preview) { described_class.new content, linkify_code_references: true }

      let(:content) { "[0101](https://example.com/existing) and 010121" }
      let(:page) { Capybara.string(rendered) }

      it "does not replace existing links" do
        expect(page).to have_link "0101", href: "https://example.com/existing"
      end

      it "links plain text code references after an existing link" do
        expect(page).to have_link "010121", href: "#{TradeTariffAdmin.frontend_host}/search?q=010121"
      end
    end
  end
end
