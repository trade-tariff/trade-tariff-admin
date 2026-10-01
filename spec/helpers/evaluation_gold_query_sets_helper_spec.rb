RSpec.describe EvaluationGoldQuerySetsHelper, type: :helper do
  describe "#gold_query_set_status_tag" do
    {
      "generating" => %w[Generating blue],
      "ready" => %w[Ready green],
      "partly_failed" => ["Partly failed", "yellow"],
      "failed" => %w[Failed red],
    }.each do |status, (text, colour)|
      it "shows #{status} as #{text} in #{colour}" do
        tag = Capybara.string(helper.gold_query_set_status_tag(EvaluationGoldQuerySet.new(status:)))

        expect(tag).to have_css("strong.govuk-tag.govuk-tag--#{colour}", text:)
      end
    end

    it "shows an unknown status as it is, in grey" do
      tag = Capybara.string(helper.gold_query_set_status_tag(EvaluationGoldQuerySet.new(status: "paused")))

      expect(tag).to have_css("strong.govuk-tag.govuk-tag--grey", text: "Paused")
    end
  end

  describe "#gold_query_set_progress" do
    it "counts finished items against the items picked, and leaves out failures when there are none" do
      gold_query_set = EvaluationGoldQuerySet.new(planned_count: 40, generated_count: 12, failed_count: 0)

      expect(helper.gold_query_set_progress(gold_query_set)).to eq("12 of 40 done")
    end

    it "counts a failed item as done, and says how many failed" do
      gold_query_set = EvaluationGoldQuerySet.new(planned_count: 40, generated_count: 35, failed_count: 2)

      expect(helper.gold_query_set_progress(gold_query_set)).to eq("37 of 40 done, 2 failed")
    end
  end

  describe "#gold_query_persona_label" do
    it "uses the label the item form uses" do
      expect(helper.gold_query_persona_label("emu_ordinary")).to eq("Ordinary search")
    end

    it "shows an unknown persona as words" do
      expect(helper.gold_query_persona_label("emu_expert")).to eq("Emu expert")
    end
  end

  describe "#gold_query_source_label" do
    it "names an ATaR" do
      expect(helper.gold_query_source_label("atar")).to eq("ATaR")
    end

    it "names a synthetic ATaR" do
      expect(helper.gold_query_source_label("synthetic_atar")).to eq("Synthetic ATaR")
    end

    it "shows an unknown source type as words" do
      expect(helper.gold_query_source_label("public_ruling")).to eq("Public ruling")
    end
  end
end
