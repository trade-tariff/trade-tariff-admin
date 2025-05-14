require 'rails_helper'

RSpec.describe 'Commodity Search Reference management' do
  let!(:user) { create :user, :gds_editor }
  let(:heading) { build :heading }

  let(:commodity) do
    build(
      :commodity,
      heading: {
        type: 'heading',
        id: heading.id,
        attributes: heading.attributes,
      },
    )
  end
  let(:commodity_search_reference) do
    build(
      :commodity_search_reference,
      title: 'new title',
      referenced: commodity.attributes,
    )
  end

  describe 'Search Reference creation' do
    before do
      stub_api_request("/admin/commodities/#{commodity.to_param}")
        .to_return jsonapi_success_response('commodity', commodity.attributes)

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references?page=1&per_page=200")
        .to_return jsonapi_success_response(
          'search_reference',
          [],
          'x-meta' => { pagination: { total: 1 } }.to_json,
        )

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references", :post)
        .to_return api_created_response
    end

    specify do
      ensure_on new_references_commodity_search_reference_path(commodity)
      fill_in 'Search reference', with: title
      click_button 'Create Search reference'
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end

  describe 'Search Reference deletion' do
    before do
      stub_api_request("/admin/commodities/#{commodity.to_param}")
        .to_return jsonapi_success_response('commodity', commodity.attributes)

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references?page=1&per_page=200")
        .to_return jsonapi_success_response(
          'search_reference',
          [commodity_search_reference.attributes],
          'x-meta' => { pagination: { total: 1 } }.to_json,
        )

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}", :delete)
        .to_return api_no_content_response
    end

    specify do
      ensure_on references_commodity_search_references_path(commodity)
      within(dom_id_selector(commodity_search_reference)) { click_link 'Remove' }
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end

  describe 'Search reference editing' do
    before do
      stub_api_request("/admin/commodities/#{commodity.to_param}")
        .to_return jsonapi_success_response('commodity', commodity.attributes)

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references?page=1&per_page=200")
        .to_return jsonapi_success_response(
          'search_reference',
          [commodity_search_reference.attributes],
          'x-meta' => { pagination: { total: 1 } }.to_json,
        )

      stub_api_request("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}", :patch)
        .to_return api_no_content_response
    end

    specify do
      ensure_on edit_references_commodity_search_reference_path(commodity, commodity_search_reference)
      fill_in 'Search reference', with: 'new title'
      click_button 'Update Search reference'
      verify current_path == references_commodity_search_references_path(commodity)
    end
  end
end
