require "search_reference"

# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Chapter Search Reference management" do
  let(:section) { build :section, resource_id: 1 }
  let(:chapter) do
    build(
      :chapter,
      :with_section,
      section: section.attributes.merge(resource_id: section.resource_id),
    )
  end
  let(:chapter_search_reference) do
    build(
      :chapter_search_reference,
      id: 1,
      title: "new title",
      referenced: chapter,
    )
  end

  describe "Search Reference creation" do
    before do
      # Ensure section is in chapter attributes for API response
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter_attrs)

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
      # Ensure section is in chapter attributes for API response
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter_attrs)

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
      expect(page).to have_content("Search references")
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end

  describe "Search reference editing" do
    before do
      # Ensure section is in chapter attributes for API response
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      stub_api_request("/admin/chapters/#{chapter.to_param}")
        .to_return jsonapi_success_response("chapter", chapter_attrs)

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
