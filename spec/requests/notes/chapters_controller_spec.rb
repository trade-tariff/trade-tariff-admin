RSpec.describe Notes::ChaptersController do
  include_context "with authenticated user"

  let(:chapter) { build(:chapter, description: "Live animals") }

  describe "GET #index" do
    it "returns no content" do
      get notes_chapters_path(format: :json)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #show" do
    before do
      stub_api_request("/admin/chapters/#{chapter.id}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)
    end

    it "returns the chapter as JSON", :aggregate_failures do
      get notes_chapter_path(chapter, format: :json)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to match(/json/)
    end
  end
end
