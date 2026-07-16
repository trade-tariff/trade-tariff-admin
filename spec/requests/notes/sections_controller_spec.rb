RSpec.describe Notes::SectionsController do
  subject(:rendered_page) do
    make_request
    response
  end

  include_context "with authenticated user"

  let(:section) { build(:section, chapter_from: 1, chapter_to: 10, title: "Live animals") }

  describe "GET #index" do
    before do
      stub_api_request("/admin/sections")
        .to_return jsonapi_success_response("section", [section.attributes])
    end

    let(:make_request) { get notes_sections_path }

    it "returns the sections", :aggregate_failures do
      expect(rendered_page).to have_http_status(:success)
      expect(rendered_page.body).to include("Live animals")
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/admin/sections/#{section.id}")
        .to_return jsonapi_success_response("section", section.attributes)
    end

    let(:make_request) { get notes_section_path(section, format: :json) }

    it "returns the section as JSON", :aggregate_failures do
      expect(rendered_page).to have_http_status(:success)
      expect(rendered_page.media_type).to match(/json/)
    end
  end
end
