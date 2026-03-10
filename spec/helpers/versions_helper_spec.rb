RSpec.describe VersionsHelper, type: :helper do
  def build_version(event:, changeset: nil)
    Version.new(
      event: event,
      item_type: "GoodsNomenclatureLabel",
      item_id: "123",
      object: {},
      changeset: changeset,
    )
  end

  describe "#changeset_summary" do
    it 'returns "Initial version" for create events' do
      expect(helper.changeset_summary(build_version(event: "create"))).to eq("Initial version")
    end

    it "returns field names for update events with a changeset" do
      version = build_version(event: "update", changeset: { "changed_fields" => %w[description synonyms], "changes" => {} })

      expect(helper.changeset_summary(version)).to eq("Changed: Description, Synonyms")
    end

    it "returns nil for update events without a changeset" do
      expect(helper.changeset_summary(build_version(event: "update"))).to be_nil
    end
  end

  describe "#changeset_detail_html" do
    it "returns nil when there is no changeset" do
      expect(helper.changeset_detail_html(build_version(event: "update"))).to be_nil
    end

    context "with a text diff" do
      let(:text_diff) { [{ "op" => "delete", "text" => "apples" }, { "op" => "insert", "text" => "oranges" }] }
      let(:version) { build_version(event: "update", changeset: { "changed_fields" => %w[description], "changes" => { "description" => { "type" => "text", "diff" => text_diff } } }) }
      let(:html) { helper.changeset_detail_html(version) }

      it "renders del tags for deletions" do
        expect(html).to include('<del class="diff-delete">apples</del>')
      end

      it "renders ins tags for insertions" do
        expect(html).to include('<ins class="diff-insert">oranges</ins>')
      end
    end

    context "with an array diff" do
      let(:array_change) { { "type" => "array", "added" => %w[banana], "removed" => %w[apple], "unchanged" => %w[grape] } }
      let(:version) { build_version(event: "update", changeset: { "changed_fields" => %w[synonyms], "changes" => { "synonyms" => array_change } }) }
      let(:html) { helper.changeset_detail_html(version) }

      it "renders added pills" do
        expect(html).to include("diff-pill--added")
      end

      it "renders removed pills" do
        expect(html).to include("diff-pill--removed")
      end

      it "renders unchanged pills" do
        expect(html).to include("diff-pill--unchanged")
      end
    end

    context "with a simple diff" do
      let(:version) { build_version(event: "update", changeset: { "changed_fields" => %w[stale], "changes" => { "stale" => { "type" => "simple", "old" => false, "new" => true } } }) }
      let(:html) { helper.changeset_detail_html(version) }

      it "renders del for old value" do
        expect(html).to include('<del class="diff-delete">false</del>')
      end

      it "renders ins for new value" do
        expect(html).to include('<ins class="diff-insert">true</ins>')
      end
    end
  end
end
