RSpec.describe "versions/_history_table" do
  subject(:rendered_page) { render_page && rendered }

  let(:render_page) do
    render "versions/history_table",
           versions:,
           can_restore: true,
           restore_path_helper: ->(version) { "/versions/#{version.resource_id}/restore" },
           view_path_helper: nil,
           current_oid: nil
  end

  let(:create_version) { Version.new(resource_id: 1, event: "create", whodunnit: nil, created_at: "2025-06-14T09:00:00Z", object: {}) }
  let(:update_version) { Version.new(resource_id: 2, event: "update", whodunnit: nil, created_at: "2025-06-15T10:00:00Z", object: {}, changeset: { "changed_fields" => %w[term], "changes" => {} }) }
  let(:versions) { [update_version, create_version] }

  it "renders a Restore button for the original (create) version, same as later versions" do
    expect(rendered_page).to have_css "form[action='/versions/1/restore'] button", text: "Restore"
  end

  it "renders a Restore button for later (update) versions" do
    expect(rendered_page).to have_css "form[action='/versions/2/restore'] button", text: "Restore"
  end

  context "when can_restore is false" do
    let(:render_page) do
      render "versions/history_table",
             versions:,
             can_restore: false,
             restore_path_helper: nil,
             view_path_helper: nil,
             current_oid: nil
    end

    it "renders no Restore buttons at all" do
      expect(rendered_page).to have_no_button "Restore"
    end
  end
end
