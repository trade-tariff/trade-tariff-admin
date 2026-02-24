# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Commodity Search Reference management" do
  let(:heading) { build :heading }

  let(:commodity) do
    build(
      :commodity,
      heading: {
        type: "heading",
        id: heading.id,
        attributes: heading.attributes,
      },
    )
  end
  let(:commodity_search_reference) do
    build(
      :commodity_search_reference,
      id: 3,
      title: "new title",
      referenced: commodity.attributes,
    )
  end

  describe "Search Reference creation" do
    before do
      %w[uk xi].each do |backend|
        stub_api_request("/admin/commodities/#{commodity.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("commodity", commodity.attributes)

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [],
          )

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references", :post, backend: backend)
          .to_return api_created_response
      end
    end

    specify "defaults both services selected" do
      ensure_on new_references_commodity_search_reference_path(commodity)
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "creates the reference" do
      ensure_on new_references_commodity_search_reference_path(commodity)
      fill_in "Search reference", with: title
      click_button "Create Search reference"
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end

  describe "Search Reference deletion" do
    before do
      %w[uk xi].each do |backend|
        stub_api_request("/admin/commodities/#{commodity.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("commodity", commodity.attributes)

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [commodity_search_reference.attributes],
          )

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}", :delete, backend: backend)
          .to_return api_no_content_response
      end
    end

    specify "keeps service switcher banner visible" do
      ensure_on references_commodity_search_references_path(commodity)
      expect(page).to have_content("You are currently using the")
    end

    specify "opens remove confirmation page before deleting" do
      ensure_on references_commodity_search_references_path(commodity)
      within(dom_id_selector(commodity_search_reference)) { click_link "Remove" }
      expect(page).to have_content("Remove Search reference")
    end

    specify "defaults both services on remove confirmation page" do
      ensure_on references_commodity_search_references_path(commodity)
      within(dom_id_selector(commodity_search_reference)) { click_link "Remove" }
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "removes search reference for selected services" do
      ensure_on references_commodity_search_references_path(commodity)
      within(dom_id_selector(commodity_search_reference)) { click_link "Remove" }
      click_button "Remove Search reference"
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end

  describe "Search reference editing" do
    before do
      %w[uk xi].each do |backend|
        stub_api_request("/admin/commodities/#{commodity.to_param}", :get, backend: backend)
          .to_return jsonapi_success_response("commodity", commodity.attributes)

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references", :get, backend: backend)
          .to_return jsonapi_success_response(
            "search_reference",
            [commodity_search_reference.attributes],
          )

        stub_api_request("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}", :patch, backend: backend)
          .to_return api_no_content_response
      end
    end

    specify "shows selected services on edit" do
      ensure_on edit_references_commodity_search_reference_path(commodity, commodity_search_reference)
      expect(page).to have_checked_field("UK service").and have_checked_field("Northern Ireland service")
    end

    specify "updates search reference for selected services" do
      ensure_on edit_references_commodity_search_reference_path(commodity, commodity_search_reference)
      fill_in "Search reference", with: "new title"
      click_button "Update Search reference"
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
