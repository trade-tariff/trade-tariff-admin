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
      %w[uk xi].each do |backend|
        stub_api_request("/admin/chapters/#{chapter.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("chapter", chapter_attrs)

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [],
          )

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :post, backend: backend)
          .to_return api_created_response
      end
    end

    specify "defaults both services selected" do
      ensure_on new_references_chapter_search_reference_path(chapter)
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "creates the reference" do
      ensure_on new_references_chapter_search_reference_path(chapter)
      fill_in "Search reference", with: "new title"
      click_button "Create Search reference"
      verify current_path == references_chapter_search_references_path(chapter)
    end

    specify "requires at least one service selected" do
      ensure_on new_references_chapter_search_reference_path(chapter)
      ["UK service", "Northern Ireland service"].each { |label| uncheck label }
      fill_in "Search reference", with: "new title"
      click_button "Create Search reference"
      expect(page).to have_content("Select at least one service to release this reference")
    end
  end

  describe "Search Reference deletion" do
    before do
      # Ensure section is in chapter attributes for API response
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      %w[uk xi].each do |backend|
        stub_api_request("/admin/chapters/#{chapter.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("chapter", chapter_attrs)

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [chapter_search_reference.attributes],
          )

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references/#{chapter_search_reference.to_param}", :delete, backend: backend)
          .to_return api_no_content_response
      end
    end

    specify "keeps service switcher banner visible" do
      ensure_on references_chapter_search_references_path(chapter)
      expect(page).to have_content("You are currently using the")
    end

    specify "opens remove confirmation page before deleting" do
      ensure_on references_chapter_search_references_path(chapter)
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      expect(page).to have_content("Remove Search reference")
    end

    specify "defaults both services on remove confirmation page" do
      ensure_on references_chapter_search_references_path(chapter)
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "removes search reference for selected services" do
      ensure_on references_chapter_search_references_path(chapter)
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      click_button "Remove Search reference"
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end

  describe "Search reference editing" do
    before do
      # Ensure section is in chapter attributes for API response
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      %w[uk xi].each do |backend|
        stub_api_request("/admin/chapters/#{chapter.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("chapter", chapter_attrs)

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [chapter_search_reference.attributes],
          )

        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references/#{chapter_search_reference.to_param}", :patch, backend: backend)
          .to_return api_no_content_response
      end
    end

    specify "shows selected services on edit" do
      ensure_on edit_references_chapter_search_reference_path(chapter, chapter_search_reference)
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "updates search reference for selected services" do
      ensure_on edit_references_chapter_search_reference_path(chapter, chapter_search_reference)
      fill_in "Search reference", with: "new title"
      click_button "Update Search reference"
      verify current_path == references_chapter_search_references_path(chapter)
    end

    context "when selected counterpart service is missing" do
      before do
        stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: "xi")
          .to_return jsonapi_success_response("search_reference", [])
      end

      specify "updates where present and shows missing service notice" do
        ensure_on edit_references_chapter_search_reference_path(chapter, chapter_search_reference)
        fill_in "Search reference", with: "updated title"
        click_button "Update Search reference"
        expect(page).to have_content("Not found in XI.")
      end
    end
  end

  describe "Search reference removal with missing counterpart service" do
    before do
      chapter_attrs = chapter.attributes.dup
      chapter_attrs["section"] = section.attributes.merge("resource_id" => section.resource_id)
      %w[uk xi].each do |backend|
        stub_api_request("/admin/chapters/#{chapter.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("chapter", chapter_attrs)
      end

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: "uk")
        .to_return jsonapi_success_response("search_reference", [chapter_search_reference.attributes])

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references", :get, backend: "xi")
        .to_return jsonapi_success_response("search_reference", [])

      stub_api_request("/admin/chapters/#{chapter.to_param}/search_references/#{chapter_search_reference.to_param}", :delete, backend: "uk")
        .to_return api_no_content_response
    end

    specify "removes where present and reports missing counterpart" do
      ensure_on references_chapter_search_references_path(chapter)
      within(dom_id_selector(chapter_search_reference)) { click_link "Remove" }
      click_button "Remove Search reference"
      expect(page).to have_content("Not found in XI.")
      verify current_path == references_chapter_search_references_path(chapter)
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
