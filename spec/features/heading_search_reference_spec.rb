require "search_reference"

# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Heading Search Reference management" do
  let(:chapter) { build :chapter, resource_id: "01" }

  let(:heading) do
    build(
      :heading,
      chapter: chapter.attributes.merge(resource_id: chapter.resource_id),
    )
  end
  let(:heading_search_reference) do
    build(
      :heading_search_reference,
      id: 2,
      title: "new title",
      referenced: heading.attributes,
    )
  end

  describe "Search Reference creation" do
    before do
      # Ensure chapter is in heading attributes for API response
      heading_attrs = heading.attributes.dup
      heading_attrs["chapter"] = chapter.attributes.merge("resource_id" => chapter.resource_id)
      stub_api_request("/admin/headings/#{heading.to_param}")
        .to_return jsonapi_success_response("heading", heading_attrs)

      stub_api_request("/admin/headings/#{heading.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [],
        )

      stub_api_request("/admin/headings/#{heading.to_param}/search_references", :post)
        .to_return api_created_response
    end

    specify do
      ensure_on new_references_heading_search_reference_path(heading)
      fill_in "Search reference", with: "new title"
      click_button "Create Search reference"
      verify current_path == references_heading_search_references_path(heading)
    end
  end

  describe "Search Reference deletion" do
    before do
      # Ensure chapter is in heading attributes for API response
      heading_attrs = heading.attributes.dup
      heading_attrs["chapter"] = chapter.attributes.merge("resource_id" => chapter.resource_id)
      stub_api_request("/admin/headings/#{heading.to_param}")
        .to_return jsonapi_success_response("heading", heading_attrs)

      stub_api_request("/admin/headings/#{heading.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [heading_search_reference.attributes],
        )

      stub_api_request("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}", :delete)
        .to_return api_no_content_response
    end

    specify do
      ensure_on references_heading_search_references_path(heading)
      within(dom_id_selector(heading_search_reference)) do
        click_link "Remove"
      end
      verify current_path == references_heading_search_references_path(heading)
    end
  end

  describe "Search reference editing" do
    before do
      # Ensure chapter is in heading attributes for API response
      heading_attrs = heading.attributes.dup
      heading_attrs["chapter"] = chapter.attributes.merge("resource_id" => chapter.resource_id)
      stub_api_request("/admin/headings/#{heading.to_param}")
        .to_return jsonapi_success_response("heading", heading_attrs)

      stub_api_request("/admin/headings/#{heading.to_param}/search_references")
        .to_return jsonapi_success_response(
          "search_reference",
          [heading_search_reference.attributes],
        )

      stub_api_request("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}", :patch)
        .to_return api_no_content_response
    end

    specify do
      ensure_on edit_references_heading_search_reference_path(heading, heading_search_reference)
      fill_in "Search reference", with: "flim flam"
      click_button "Update Search reference"
      verify current_path == references_heading_search_references_path(heading)
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
