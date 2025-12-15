require "search_reference"

# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Chapter Search Reference management" do
  # rubocop:disable RSpec/LetSetup
  let!(:user) { create :user, :gds_editor }
  # rubocop:enable RSpec/LetSetup
  let(:section) { build :section }
  let(:chapter_search_reference) do
    build(
      :chapter_search_reference,
      title: "new title",
      referenced: chapter,
    )
  end
  let(:chapter) do
    build(
      :chapter,
      :with_section,
      section: { id: section.id, attributes: section.attributes },
    )
  end

  describe "Search Reference creation" do
    before do
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [],
        )

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :post)
        .to_return api_created_response
    end

    specify do
      ensure_on new_references_chapter_search_reference_path(chapter)
      fill_in "Search reference", with: "new title"
      click_button "Create Search reference"
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end

  describe "Search Reference deletion" do
    before do
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [chapter_search_reference.attributes],
        )

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references/#{chapter_search_reference.to_param}", :delete)
        .to_return api_no_content_response
    end

    specify do
      ensure_on references_chapter_search_references_path(chapter)
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end

  describe "Search reference editing" do
    before do
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [chapter_search_reference.attributes],
        )

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references/#{chapter_search_reference.to_param}", :patch)
        .to_return api_no_content_response
    end

    specify do
      ensure_on edit_references_chapter_search_reference_path(chapter, chapter_search_reference)
      fill_in "Search reference", with: "new title"
      click_button "Update Search reference"
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
