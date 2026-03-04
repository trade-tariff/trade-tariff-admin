RSpec.describe GoodsNomenclatureSelfText do
  subject(:self_text) { described_class.new(attributes) }

  let(:attributes) do
    {
      goods_nomenclature_sid: 12_345,
      goods_nomenclature_item_id: "0101210000",
      self_text: "Live horses for breeding or racing purposes",
      generation_type: "mechanical",
      input_context: {
        "goods_nomenclature_class" => "commodity",
        "description" => "Horses",
        "ancestors" => [
          { "description" => "Live animals" },
          { "description" => "Live horses, asses, mules and hinnies" },
        ],
        "siblings" => ["Pure-bred breeding animals", "Other"],
      },
      needs_review: false,
      manually_edited: false,
      stale: false,
      generated_at: "2025-06-15T10:00:00Z",
      eu_self_text: "Horses, live, for breeding",
      similarity_score: 0.72,
      coherence_score: 0.68,
      nomenclature_type: "commodity",
      score: 0.70,
    }
  end

  describe "#combined_score" do
    it "averages similarity and coherence scores when both present" do
      expect(self_text.combined_score).to eq(0.70)
    end

    it "returns similarity_score when coherence_score is nil" do
      self_text.coherence_score = nil

      expect(self_text.combined_score).to eq(0.72)
    end

    it "returns coherence_score when similarity_score is nil" do
      self_text.similarity_score = nil

      expect(self_text.combined_score).to eq(0.68)
    end

    it "returns nil when both scores are nil" do
      self_text.similarity_score = nil
      self_text.coherence_score = nil

      expect(self_text.combined_score).to be_nil
    end
  end

  describe "#score_kind" do
    it "returns Combined when both scores present" do
      expect(self_text.score_kind).to eq("Combined")
    end

    it "returns Similarity when only similarity_score present" do
      self_text.coherence_score = nil

      expect(self_text.score_kind).to eq("Similarity")
    end

    it "returns Coherence when only coherence_score present" do
      self_text.similarity_score = nil

      expect(self_text.score_kind).to eq("Coherence")
    end

    it "returns nil when neither score present" do
      self_text.similarity_score = nil
      self_text.coherence_score = nil

      expect(self_text.score_kind).to be_nil
    end
  end

  describe "#score_label" do
    it "returns Amazing for combined score >= 0.85" do
      self_text.similarity_score = 0.90
      self_text.coherence_score = 0.90

      expect(self_text.score_label).to eq("Amazing")
    end

    it "returns Good for combined score >= 0.5" do
      expect(self_text.score_label).to eq("Good")
    end

    it "returns Okay for combined score >= 0.3" do
      self_text.similarity_score = 0.35
      self_text.coherence_score = 0.25

      expect(self_text.score_label).to eq("Okay")
    end

    it "returns Bad for combined score < 0.3" do
      self_text.similarity_score = 0.1
      self_text.coherence_score = 0.1

      expect(self_text.score_label).to eq("Bad")
    end

    it "returns No score when combined score is nil" do
      self_text.similarity_score = nil
      self_text.coherence_score = nil

      expect(self_text.score_label).to eq("No score")
    end
  end

  describe "#score_tag_colour" do
    it "returns blue for Amazing" do
      self_text.similarity_score = 0.90
      self_text.coherence_score = 0.90

      expect(self_text.score_tag_colour).to eq("blue")
    end

    it "returns green for Good" do
      expect(self_text.score_tag_colour).to eq("green")
    end

    it "returns grey for no score" do
      self_text.similarity_score = nil
      self_text.coherence_score = nil

      expect(self_text.score_tag_colour).to eq("grey")
    end
  end

  describe "#formatted_generated_at" do
    it "returns the formatted date" do
      self_text.generated_at = "2025-06-15T10:00:00Z"

      expect(self_text.formatted_generated_at).not_to eq("-")
    end

    it "returns dash when generated_at is blank" do
      self_text.generated_at = nil

      expect(self_text.formatted_generated_at).to eq("-")
    end
  end

  describe "#ancestor_chain" do
    it "returns ancestor descriptions" do
      expect(self_text.ancestor_chain).to eq(["Live animals", "Live horses, asses, mules and hinnies"])
    end

    it "returns empty array when input_context is nil" do
      self_text.input_context = nil

      expect(self_text.ancestor_chain).to eq([])
    end

    it "uses self_text for ancestors with 'other' description" do
      self_text.input_context = { "ancestors" => [{ "description" => "Other", "self_text" => "Specific description" }] }

      expect(self_text.ancestor_chain).to eq(["Specific description"])
    end
  end

  describe "#kind" do
    it "returns the goods_nomenclature_class from input_context" do
      expect(self_text.kind).to eq("commodity")
    end

    it "returns nil when input_context is nil" do
      self_text.input_context = nil

      expect(self_text.kind).to be_nil
    end
  end

  describe "#context_description" do
    it "returns the description from input_context" do
      expect(self_text.context_description).to eq("Horses")
    end

    it "returns nil when input_context is nil" do
      self_text.input_context = nil

      expect(self_text.context_description).to be_nil
    end
  end

  describe "#context_siblings" do
    it "returns siblings from input_context" do
      expect(self_text.context_siblings).to eq(["Pure-bred breeding animals", "Other"])
    end

    it "returns empty array when input_context is nil" do
      self_text.input_context = nil

      expect(self_text.context_siblings).to eq([])
    end
  end

  describe "#to_param" do
    it "returns goods_nomenclature_sid as string" do
      expect(self_text.to_param).to eq("12345")
    end

    it "falls back to goods_nomenclature_id" do
      record = described_class.new(goods_nomenclature_id: "99999")

      expect(record.to_param).to eq("99999")
    end
  end
end
