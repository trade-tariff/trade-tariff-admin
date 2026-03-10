RSpec.describe GoodsNomenclatureLabel do
  subject(:label) { described_class.new(attributes) }

  let(:attributes) do
    {
      goods_nomenclature_sid: 12_345,
      goods_nomenclature_item_id: "0101210000",
      goods_nomenclature_type: "commodity",
      producline_suffix: "80",
      stale: false,
      manually_edited: false,
      context_hash: "abc123",
      labels: {
        "original_description" => "Live horses",
        "description" => "Horses (live)",
        "known_brands" => %w[Brand1 Brand2],
        "colloquial_terms" => %w[Ponies Nags],
        "synonyms" => %w[Equine Steeds],
      },
      description_score: 0.72,
      score: 0.70,
    }
  end

  describe "label field accessors" do
    it "returns description from labels hash" do
      expect(label.description).to eq("Horses (live)")
    end

    it "returns original_description from labels hash" do
      expect(label.original_description).to eq("Live horses")
    end

    it "prefers top-level original_description over labels hash" do
      attrs = attributes.merge(original_description: "Top-level description")
      record = described_class.new(attrs)

      expect(record.original_description).to eq("Top-level description")
    end

    it "returns known_brands from labels hash" do
      expect(label.known_brands).to eq(%w[Brand1 Brand2])
    end

    it "returns colloquial_terms from labels hash" do
      expect(label.colloquial_terms).to eq(%w[Ponies Nags])
    end

    it "returns synonyms from labels hash" do
      expect(label.synonyms).to eq(%w[Equine Steeds])
    end

    it "returns empty known_brands when labels is nil" do
      expect(described_class.new(labels: nil).known_brands).to eq([])
    end

    it "returns empty colloquial_terms when labels is nil" do
      expect(described_class.new(labels: nil).colloquial_terms).to eq([])
    end

    it "returns empty synonyms when labels is nil" do
      expect(described_class.new(labels: nil).synonyms).to eq([])
    end
  end

  describe "text conversion" do
    it "converts known_brands to newline-separated text" do
      expect(label.known_brands_text).to eq("Brand1\nBrand2")
    end

    it "converts colloquial_terms to newline-separated text" do
      expect(label.colloquial_terms_text).to eq("Ponies\nNags")
    end

    it "converts synonyms to newline-separated text" do
      expect(label.synonyms_text).to eq("Equine\nSteeds")
    end

    it "sets known_brands from text" do
      label.known_brands_text = "Alpha\nBeta\nGamma"

      expect(label.known_brands).to eq(%w[Alpha Beta Gamma])
    end

    it "sets colloquial_terms from text" do
      label.colloquial_terms_text = "Term1\nTerm2"

      expect(label.colloquial_terms).to eq(%w[Term1 Term2])
    end

    it "sets synonyms from text" do
      label.synonyms_text = "Syn1\nSyn2"

      expect(label.synonyms).to eq(%w[Syn1 Syn2])
    end

    it "strips blank lines and whitespace" do
      label.known_brands_text = "  Alpha \n\n  Beta  \n"

      expect(label.known_brands).to eq(%w[Alpha Beta])
    end

    it "returns empty array for blank text" do
      label.known_brands_text = ""

      expect(label.known_brands).to eq([])
    end
  end

  describe "#description=" do
    it "sets description in the labels hash" do
      label.description = "New description"

      expect(label.labels["description"]).to eq("New description")
    end
  end

  describe "#score_label" do
    it "returns Amazing for score >= 0.85" do
      record = described_class.new(description_score: 0.90)

      expect(record.score_label).to eq("Amazing")
    end

    it "returns Good for score >= 0.5" do
      record = described_class.new(description_score: 0.72)

      expect(record.score_label).to eq("Good")
    end

    it "returns Okay for score >= 0.3" do
      record = described_class.new(description_score: 0.35)

      expect(record.score_label).to eq("Okay")
    end

    it "returns Bad for score < 0.3" do
      record = described_class.new(description_score: 0.1)

      expect(record.score_label).to eq("Bad")
    end

    it "returns No score when nil" do
      record = described_class.new(description_score: nil)

      expect(record.score_label).to eq("No score")
    end
  end

  describe "#score_tag_colour" do
    it "returns blue for Amazing scores" do
      record = described_class.new(description_score: 0.90)

      expect(record.score_tag_colour).to eq("blue")
    end

    it "returns green for Good scores" do
      record = described_class.new(description_score: 0.60)

      expect(record.score_tag_colour).to eq("green")
    end

    it "returns yellow for Okay scores" do
      record = described_class.new(description_score: 0.35)

      expect(record.score_tag_colour).to eq("yellow")
    end

    it "returns red for Bad scores" do
      record = described_class.new(description_score: 0.1)

      expect(record.score_tag_colour).to eq("red")
    end

    it "returns grey when nil" do
      record = described_class.new(description_score: nil)

      expect(record.score_tag_colour).to eq("grey")
    end
  end

  describe "#to_param" do
    it "returns goods_nomenclature_id when set" do
      label.goods_nomenclature_id = "0101210000"

      expect(label.to_param).to eq("0101210000")
    end

    it "falls back to goods_nomenclature_item_id" do
      expect(label.to_param).to eq("0101210000")
    end
  end
end
