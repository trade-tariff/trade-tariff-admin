require "rails_helper"

RSpec.describe TariffNoteFormatter do
  subject(:result) { described_class.new(content).format }

  describe "note number spacing normalisation" do
    context "when the note number is immediately followed by text with no space" do
      let(:content) { "8.In this section, the following expressions have the meanings hereby assigned to them:" }

      it "adds a space after the period so Govspeak treats it as a list marker" do
        expect(result).to eq "8. In this section, the following expressions have the meanings hereby assigned to them:"
      end
    end

    context "when the note number already has a space" do
      let(:content) { "1. This section does not cover:" }

      it "is unchanged" do
        expect(result).to eq "1. This section does not cover:"
      end
    end
  end

  describe "passthrough — no ETL patterns" do
    let(:content) { "Some plain text with no special patterns." }

    it "returns the content unchanged" do
      expect(result).to eq content
    end
  end

  describe "rule 3: lettered sub-items" do
    context "when text starts with lowercase" do
      let(:content) { "a. having regard to the manner in which they are put up;" }

      it "adds four-space indent, no bold" do
        expect(result).to eq "    a. having regard to the manner in which they are put up;"
      end
    end

    context "when text starts with uppercase but ends with a period" do
      let(:content) { "a. An alloy of base metals is to be classified as an alloy of the metal which predominates by weight over each of the other metals." }

      it "does not bold — period at end indicates a complete sentence, not a title" do
        expect(result).to eq "    a. An alloy of base metals is to be classified as an alloy of the metal which predominates by weight over each of the other metals."
      end
    end

    context "when text starts with uppercase but ends with ' and'" do
      let(:content) { "a. Chapters 50 to 55 and 60 and, except where the context otherwise requires, Chapters 56 to 59 do not apply to goods made up within the meaning of note 7 above; and" }

      it "does not bold — trailing ' and' marks a continuing list item, not a title" do
        expect(result).to eq "    a. Chapters 50 to 55 and 60 and, except where the context otherwise requires, Chapters 56 to 59 do not apply to goods made up within the meaning of note 7 above; and"
      end
    end

    context "when text starts with uppercase — definition title" do
      let(:content) { "a. Waste and scrap" }

      it "adds four-space indent and bold markers" do
        expect(result).to eq "    **a. Waste and scrap**"
      end
    end

    context "with the EU ij. digraph" do
      let(:content) { "ij. woven, knitted or crocheted fabrics, of Chapter 40;" }

      it "handles two-letter label correctly" do
        expect(result).to eq "    ij. woven, knitted or crocheted fabrics, of Chapter 40;"
      end
    end
  end

  describe "rule 4: capital bracket sub-paragraphs (B)-(Z)" do
    context "with a full sentence and terminal punctuation" do
      let(:content) { "(B) Subject to paragraph (A) above, goods answering to a description in heading 2843;" }

      it "adds four-space indent, no bold" do
        expect(result).to eq "    (B) Subject to paragraph (A) above, goods answering to a description in heading 2843;"
      end
    end

    context "with a colon introducing sub-items" do
      let(:content) { "(B) For the purposes of the above rule:" }

      it "adds four-space indent, no bold" do
        expect(result).to eq "    (B) For the purposes of the above rule:"
      end
    end
  end

  describe "rule 5: lowercase bracket sub-items (a)-(z)" do
    context "when text starts with uppercase — definition title" do
      let(:content) { "(a) Bars and rods" }

      it "adds four-space indent and bold markers" do
        expect(result).to eq "    **(a) Bars and rods**"
      end
    end

    context "when text starts with lowercase" do
      let(:content) { "(a) where appropriate, only the part which determines the classification;" }

      it "adds four-space indent, no bold" do
        expect(result).to eq "    (a) where appropriate, only the part which determines the classification;"
      end
    end
  end

  describe "rule 6: numbered bracket sub-sub-items" do
    let(:content) { "(1) polished or glazed, measuring 1.429 decitex or more; or" }

    it "adds four-space indent" do
      expect(result).to eq "    (1) polished or glazed, measuring 1.429 decitex or more; or"
    end
  end

  describe "rule 7: bullet character (•)" do
    let(:content) { "•of rectangular (including square) shape with a thickness not exceeding one-tenth of the width;" }

    it "converts to a Govspeak sub-bullet" do
      expect(result).to eq "  - of rectangular (including square) shape with a thickness not exceeding one-tenth of the width;"
    end
  end

  describe "rule 2: known section headings" do
    context "when content is 'Subheading notes'" do
      let(:content) { "Subheading notes" }

      it "promotes to h3" do
        expect(result).to eq "### Subheading notes"
      end
    end

    context "when content is 'Additional section notes'" do
      let(:content) { "Additional section notes" }

      it "promotes to h3" do
        expect(result).to eq "### Additional section notes"
      end
    end
  end

  describe "rule 8: continuation paragraph indentation" do
    context "when plain prose immediately follows a numbered note" do
      let(:content) do
        "2. (A) Goods classifiable in Chapters 50 to 55.\n\n" \
        "When no one textile material predominates by weight, the goods are to be classified accordingly."
      end

      it "indents the continuation paragraph with four spaces" do
        expect(result).to eq(
          "2. (A) Goods classifiable in Chapters 50 to 55.\n\n" \
          "    When no one textile material predominates by weight, the goods are to be classified accordingly.",
        )
      end
    end

    context "when plain prose appears before any numbered note" do
      let(:content) { "Some introductory text.\n\nMore introductory text." }

      it "does not indent — no numbered note has been seen yet" do
        expect(result).to eq "Some introductory text.\n\nMore introductory text."
      end
    end

    context "when a known section heading appears after a numbered note" do
      let(:content) { "15. Some note.\n\nSubheading notes\n\n1. Another note." }

      it "promotes the heading to h3 and does not indent it" do
        expect(result).to eq "15. Some note.\n\n### Subheading notes\n\n1. Another note."
      end
    end
  end

  describe "rule 1: em-dash table" do
    let(:content) do
      <<~TEXT.chomp
        — single yarn of nylon or other polyamides, or of polyesters:
        60 cN/tex,
        — multiple (folded) or cabled yarn of nylon or other polyamides, or of polyesters:
        53 cN/tex,
        — single, multiple (folded) or cabled yarn of viscose rayon:
        27 cN/tex.
      TEXT
    end

    let(:expected_table) do
      <<~TABLE.chomp
        |   |   |
        |---|---|
        | — single yarn of nylon or other polyamides, or of polyesters: | 60 cN/tex, |
        | — multiple (folded) or cabled yarn of nylon or other polyamides, or of polyesters: | 53 cN/tex, |
        | — single, multiple (folded) or cabled yarn of viscose rayon: | 27 cN/tex. |
      TABLE
    end

    it "converts em-dash pairs to a blank-header Govspeak table" do
      expect(result).to eq expected_table
    end
  end
end
