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

  describe "#side_by_side_diff_html" do
    def build_note_with_text_diff(ops)
      build_version(
        event: "update",
        changeset: {
          "changed_fields" => %w[content],
          "changes" => { "content" => { "type" => "text", "diff" => ops } },
        },
      )
    end

    let(:ops) do
      [
        { "op" => "equal",  "text" => "Common text. " },
        { "op" => "delete", "text" => "old word" },
        { "op" => "insert", "text" => "new word" },
      ]
    end

    let(:html) { helper.side_by_side_diff_html(build_note_with_text_diff(ops), from_version: "1.31", to_version: "1.32") }

    it "returns nil when there is no changeset" do
      note = build_version(event: "update")
      expect(helper.side_by_side_diff_html(note, from_version: "1.31", to_version: "1.32")).to be_nil
    end

    it "wraps output in a diff-side-by-side container" do
      expect(html).to include('class="diff-side-by-side"')
    end

    it "renders the from_version label" do
      expect(html).to include("1.31")
    end

    it "renders the to_version label" do
      expect(html).to include("1.32")
    end

    it "renders deleted text wrapped in del" do
      expect(html).to include('<del class="diff-delete">old word</del>')
    end

    it "renders inserted text wrapped in ins" do
      expect(html).to include('<ins class="diff-insert">new word</ins>')
    end

    it "deleted text appears only once (left panel only)" do
      expect(html.scan("old word").count).to eq(1)
    end

    it "inserted text appears only once (right panel only)" do
      expect(html.scan("new word").count).to eq(1)
    end

    it "equal text appears in both panels" do
      expect(html.scan("Common text.").count).to eq(2)
    end

    context "with a non-text (array) change type" do
      let(:array_change) do
        { "type" => "array", "added" => %w[banana], "removed" => %w[apple], "unchanged" => [] }
      end

      let(:array_html) do
        note = build_version(
          event: "update",
          changeset: {
            "changed_fields" => %w[tags],
            "changes" => { "tags" => array_change },
          },
        )
        helper.side_by_side_diff_html(note, from_version: "1.31", to_version: "1.32")
      end

      it "falls back to inline rendering with added pills" do
        expect(array_html).to include("diff-pill--added")
      end

      it "falls back to inline rendering with removed pills" do
        expect(array_html).to include("diff-pill--removed")
      end
    end
  end
end
