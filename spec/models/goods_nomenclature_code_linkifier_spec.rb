RSpec.describe GoodsNomenclatureCodeLinkifier do
  let(:frontend_host) { "https://example.com" }

  def render(html)
    described_class.new(html, frontend_host:, service_path: "").render
  end

  def page(html)
    Capybara.string(render(html))
  end

  describe "#render" do
    context "with a Chapter keyword reference" do
      it "linkifies the chapter" do
        expect(page("<p>goods of Chapter 71</p>")).to have_link("Chapter 71", href: "https://example.com/search?q=71")
      end
    end

    context "with multiple 4-digit heading codes using mixed separators" do
      let(:html) { "<p>(headings 3207 to 3210, 3212, 3213 or 3215)</p>" }
      let(:rendered) { page(html) }

      it "linkifies codes followed by a space and word" do
        expect(rendered).to have_link("3213", href: "https://example.com/search?q=3213")
      end

      it "linkifies codes followed by a comma" do
        expect(rendered).to have_link("3212", href: "https://example.com/search?q=3212")
      end

      it "linkifies codes followed by a closing parenthesis" do
        expect(rendered).to have_link("3215", href: "https://example.com/search?q=3215")
      end
    end

    context "with a 2-digit chapter code at the end of a sentence" do
      let(:html) { "<p>excluded from Chapters 72 to 81.</p>" }

      it "linkifies the chapter code" do
        expect(page(html)).to have_link("81", href: "https://example.com/search?q=81")
      end

      it "does not include the period in the link" do
        expect(render(html)).to match(%r{</a>\.})
      end
    end

    context "with a decimal number" do
      it "does not linkify numbers before a decimal point" do
        expect(page("<p>a thickness not exceeding one-tenth of the width exceeds 10.5mm</p>")).not_to have_link("10")
      end
    end

    context "with a code inside an existing link" do
      it "does not double-linkify" do
        html = '<p><a href="/foo">3606</a></p>'

        expect(render(html)).not_to match(%r{<a [^>]*>.*<a}m)
      end
    end

    it "places the space inside the visually hidden span so there is no trailing whitespace in the link text" do
      expect(render("<p>heading 3606</p>")).to include('3606<span class="govuk-visually-hidden"> (opens in new tab)</span>')
    end
  end
end
