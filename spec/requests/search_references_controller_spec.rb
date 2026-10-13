# rubocop:disable RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe SearchReferencesController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:search_reference_id) { "34" }
  let(:make_request) { get search_reference_path(search_reference_id) }
  let(:page) { Capybara.string(rendered_page.body) }
  let(:version_meta) do
    { current: true, oid: 5, previous_oid: 4, has_previous_version: true, latest_event: "update" }
  end

  let(:search_reference_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: {
          id: search_reference_id,
          type: "search_reference",
          attributes: {
            title: "horses",
            referenced_class: "Heading",
            goods_nomenclature_item_id: "0101000000",
            productline_suffix: "80",
            goods_nomenclature_sid: 100,
            usage: "search",
          },
        },
        meta: { version: version_meta },
      }.to_json,
    }
  end

  let(:versions_response) do
    {
      status: 200,
      headers: { "content-type" => "application/json; charset=utf-8" },
      body: {
        data: [
          { id: "5", type: "version", attributes: { item_type: "SearchReference", item_id: search_reference_id, event: "update", object: { "title" => "horses" } } },
          { id: "4", type: "version", attributes: { item_type: "SearchReference", item_id: search_reference_id, event: "create", object: { "title" => "horse" } } },
        ],
      }.to_json,
    }
  end

  before do
    stub_api_request("/search_references/#{search_reference_id}").and_return(search_reference_response)
    stub_api_request("/versions")
      .with(query: hash_including("item_type" => "SearchReference", "item_id" => search_reference_id))
      .and_return(versions_response)
  end

  it { is_expected.to have_http_status :success }

  it "shows the search reference" do
    expect(page).to have_css("h1", text: "horses")
    expect(page).to have_text("0101000000-80")
    expect(page).to have_text("Public search and FPO training")
  end

  it "links to the heading's search references" do
    expect(page).to have_link("Manage search references for heading 0101000000-80", href: references_heading_search_references_path("0101"))
  end

  it "shows the version history with restore controls" do
    expect(page).to have_text("Version history (2)")
    expect(page).to have_button("Restore", visible: :all)
  end

  context "when viewing a historical version" do
    let(:make_request) { get search_reference_path(search_reference_id, oid: "4") }
    let(:version_meta) do
      { current: false, oid: 4, previous_oid: nil, has_previous_version: false, latest_event: "update" }
    end

    before do
      stub_api_request("/search_references/#{search_reference_id}")
        .with(query: hash_including("filter" => { "oid" => "4" }))
        .and_return(search_reference_response)
    end

    it "shows the historical version banner" do
      expect(page).to have_text("You are viewing a historical version of this search reference.")
      expect(page).to have_link("View current version", href: search_reference_path(search_reference_id))
    end

    it "does not link to the management screen" do
      expect(page).to have_no_link(href: references_heading_search_references_path("0101"))
    end
  end

  context "when the search reference has been deleted" do
    let(:make_request) { get search_reference_path(search_reference_id, oid: "6") }
    let(:version_meta) do
      { current: false, oid: 6, previous_oid: 5, has_previous_version: true, latest_event: "destroy" }
    end

    before do
      stub_api_request("/search_references/#{search_reference_id}")
        .with(query: hash_including("filter" => { "oid" => "6" }))
        .and_return(search_reference_response)
    end

    it "explains that it has been deleted and offers a restore" do
      expect(page).to have_text("This search reference has been deleted.")
      expect(page).to have_button("Restore this version")
      expect(page).to have_no_link("View current version")
    end
  end

  context "when the search reference does not exist" do
    before do
      stub_api_request("/search_references/#{search_reference_id}").and_return(status: 404, body: { error: "Not found" }.to_json)
    end

    it { is_expected.to redirect_to(versions_path(item_type: "SearchReference")) }
  end

  context "when the user is an auditor" do
    let(:current_user) { create(:user, :auditor) }

    it "shows the page without restore controls" do
      expect(rendered_page).to have_http_status :success
      expect(page).to have_no_button("Restore", visible: :all)
    end
  end

  context "when the user is a guest" do
    let(:current_user) { create(:user, :guest) }

    it { is_expected.to have_http_status :forbidden }
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
