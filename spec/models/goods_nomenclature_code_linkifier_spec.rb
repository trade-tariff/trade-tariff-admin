RSpec.describe GoodsNomenclatureCodeLinkifier do
  let(:frontend_host) { "https://example.com" }

  def render(html)
    described_class.new(html, frontend_host:, service_path: "").render
  end

  def page(html)
    Capybara.string(render(html))
  end

  def link_texts(rendered)
    rendered.all("a").map { |link| link.text.gsub(/ \(opens in new tab\)\z/, "") }
  end

  def linked_code_only?(rendered, phrase, code, href)
    rendered.has_text?(phrase) &&
      rendered.has_link?(code, href:) &&
      link_texts(rendered).exclude?(phrase)
  end

  describe "#render" do
    context "with a Chapter keyword reference" do
      it "linkifies the chapter" do
        rendered = page("<p>goods of Chapter 71</p>")

        expect(linked_code_only?(rendered, "Chapter 71", "71", "https://example.com/search?q=71")).to be(true)
      end
    end

    context "with a single-digit chapter reference" do
      it "linkifies the chapter and zero-pads the search code" do
        rendered = page("<p>Heading 1005 does not cover sweetcorn (Chapter 7)</p>")

        expect(linked_code_only?(rendered, "Chapter 7", "7", "https://example.com/search?q=07")).to be(true)
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

    context "with a code followed by a colon" do
      it "linkifies the whole code instead of splitting the final pair as a chapter" do
        rendered = page("<p>for the purposes of code 0202 20 10: forequarters</p>")

        expect(rendered).to have_link("0202 20 10", href: "https://example.com/search?q=02022010")
          .and have_no_link(href: "https://example.com/search?q=10")
      end
    end

    context "with a ten-digit code separated by spaces" do
      it "linkifies the whole code instead of splitting the suffix as a chapter" do
        rendered = page("<p>Code 1001 19 00 18 High quality durum wheat</p>")

        expect(rendered).to have_link("1001 19 00 18", href: "https://example.com/search?q=1001190018")
          .and have_no_link(href: "https://example.com/search?q=18")
      end
    end

    context "with a ten-digit code using compact middle spacing" do
      it "linkifies the whole code instead of splitting it into headings" do
        rendered = page("<p>Code 2404 1200 90 applies.</p>")

        expect(rendered).to have_link("2404 1200 90", href: "https://example.com/search?q=2404120090")
          .and have_no_link(href: "https://example.com/search?q=1200")
      end
    end

    context "with an eight-digit code using compact middle spacing" do
      it "linkifies the whole code instead of splitting it into headings" do
        rendered = page("<p>codes 2710 2011 to 2710 2090</p>")

        expect(rendered).to have_link("2710 2011", href: "https://example.com/search?q=27102011")
          .and have_link("2710 2090", href: "https://example.com/search?q=27102090")
          .and have_no_link(href: "https://example.com/search?q=2011")
      end
    end

    context "with non-breaking spaces around a code" do
      it "linkifies the whole code instead of splitting it" do
        rendered = page("<p>For subheadings 8549 11\u00A0to 8549 19\u00A0, spent cells are covered.</p>")

        expect(rendered).to have_link("8549 11", href: "https://example.com/search?q=854911")
          .and have_link("8549 19", href: "https://example.com/search?q=854919")
          .and have_no_link(href: "https://example.com/search?q=11")
          .and have_no_link(href: "https://example.com/search?q=19")
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

    context "with a chapter list" do
      it "linkifies continuation chapters in the list" do
        rendered = page("<p>goods of Chapter 39, 40 or 63.</p>")

        expect(link_texts(rendered)).to eq(%w[39 40 63])
      end
    end

    context "with a decimal number" do
      it "does not linkify numbers before a decimal point" do
        expect(page("<p>a thickness not exceeding one-tenth of the width exceeds 10.5mm</p>")).not_to have_link("10")
      end
    end

    context "with percentages" do
      it "does not linkify percentage values as chapter codes" do
        rendered = page("<p>not more than 10 % of chromium and 30% of manganese</p>")

        expect(rendered).to have_no_link("10")
          .and have_no_link("30")
      end
    end

    context "with measurement values" do
      it "does not linkify bare quantities as chapter codes" do
        rendered = page("<p>at least 10 times the thickness, exceeds 15 mm but not 52 mm, under a current of 50 Hz.</p>")

        expect(rendered).to have_no_link("10")
          .and have_no_link("15")
          .and have_no_link("52")
          .and have_no_link("50")
      end
    end

    context "with legal references" do
      it "does not linkify bare article numbers as chapter codes" do
        rendered = page("<p>Article 45 of Regulation (EU) 33/2019.</p>")

        expect(rendered).to have_no_link("45")
          .and have_no_link("33")
      end
    end

    context "with standard references" do
      it "does not linkify ISO method numbers as heading codes" do
        rendered = page("<p>ISO 8069:2005 method and EN ISO 3104 method.</p>")

        expect(rendered).to have_no_link("8069")
          .and have_no_link("2005")
          .and have_no_link("3104")
      end
    end

    context "with regulation years" do
      it "does not linkify years as heading codes" do
        rendered = page("<p>The Seed Potatoes Regulations 1991 and Cereal Seeds Regulation 1974 apply.</p>")

        expect(rendered).to have_no_link("1991")
          .and have_no_link("1974")
      end
    end

    context "with publication years" do
      it "does not linkify edition years as heading codes" do
        rendered = page("<p>Rewe Colour Index, third edition 1971.</p>")

        expect(rendered).to have_no_link("1971")
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
