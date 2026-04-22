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
      needs_review: false,
      approved: false,
      expired: false,
      context_hash: "abc123",
      created_at: "2025-06-15T10:00:00Z",
      updated_at: "#{Time.zone.today.iso8601}T10:00:00Z",
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
    it "returns Very High for score >= 0.85" do
      record = described_class.new(description_score: 0.90)

      expect(record.score_label).to eq("Very High")
    end

    it "returns High for score >= 0.5" do
      record = described_class.new(description_score: 0.72)

      expect(record.score_label).to eq("High")
    end

    it "returns Medium for score >= 0.3" do
      record = described_class.new(description_score: 0.35)

      expect(record.score_label).to eq("Medium")
    end

    it "returns Low for score < 0.3" do
      record = described_class.new(description_score: 0.1)

      expect(record.score_label).to eq("Low")
    end

    it "returns No score when nil" do
      record = described_class.new(description_score: nil)

      expect(record.score_label).to eq("No score")
    end
  end

  describe "#score_tag_colour" do
    it "returns green for Very High scores" do
      record = described_class.new(description_score: 0.90)

      expect(record.score_tag_colour).to eq("green")
    end

    it "returns blue for High scores" do
      record = described_class.new(description_score: 0.60)

      expect(record.score_tag_colour).to eq("blue")
    end

    it "returns yellow for Medium scores" do
      record = described_class.new(description_score: 0.35)

      expect(record.score_tag_colour).to eq("yellow")
    end

    it "returns grey for Low scores" do
      record = described_class.new(description_score: 0.1)

      expect(record.score_tag_colour).to eq("grey")
    end

    it "returns grey when nil" do
      record = described_class.new(description_score: nil)

      expect(record.score_tag_colour).to eq("grey")
    end
  end

  describe "record date formatting" do
    it "formats created_at" do
      expect(label.formatted_created_at).to eq("15 June 2025")
    end

    it "returns Today when updated_at is today" do
      expect(label.formatted_updated_at).to eq("Today")
    end

    it "returns dash when a date is blank" do
      label.updated_at = nil

      expect(label.formatted_updated_at).to eq("-")
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

  describe "#as_listing_json" do
    it "includes lifecycle tag fields" do
      record = described_class.new(attributes.merge(lifecycle_tag_attributes))

      expect(record.as_listing_json).to include(lifecycle_tag_attributes)
    end
  end

  def lifecycle_tag_attributes
    { needs_review: true, manually_edited: true, stale: true, approved: true, expired: true }
  end

  describe "#generate_score" do
    it "posts to the label score endpoint" do
      stub_api_request("/goods_nomenclatures/0101210000/goods_nomenclature_label/score", :post)
        .and_return(status: 200, body: {}.to_json)

      label.generate_score

      expect(WebMock).to have_requested(:post, /goods_nomenclatures\/0101210000\/goods_nomenclature_label\/score/)
    end
  end

  describe "#regenerate" do
    it "posts to the label regenerate endpoint" do
      stub_api_request("/goods_nomenclatures/0101210000/goods_nomenclature_label/regenerate", :post)
        .and_return(status: 200, body: {}.to_json)

      label.regenerate

      expect(WebMock).to have_requested(:post, /goods_nomenclatures\/0101210000\/goods_nomenclature_label\/regenerate/)
    end
  end

  describe "#approve" do
    it "posts to the label approve endpoint" do
      stub_api_request("/goods_nomenclatures/0101210000/goods_nomenclature_label/approve", :post)
        .and_return(status: 200, body: {}.to_json)

      label.approve

      expect(WebMock).to have_requested(:post, /goods_nomenclatures\/0101210000\/goods_nomenclature_label\/approve/)
    end
  end

  describe "#reject" do
    it "posts to the label reject endpoint" do
      stub_api_request("/goods_nomenclatures/0101210000/goods_nomenclature_label/reject", :post)
        .and_return(status: 200, body: {}.to_json)

      label.reject

      expect(WebMock).to have_requested(:post, /goods_nomenclatures\/0101210000\/goods_nomenclature_label\/reject/)
    end
  end
end
