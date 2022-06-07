require 'rails_helper'
require 'search_reference'

RSpec.describe 'Commodity Search Reference management' do
  let!(:user)   { create :user, :gds_editor }
  let(:heading) { build :heading }

  describe 'Search Reference creation' do
    let(:title)        { 'new title' }
    let(:commodity)    { build :commodity, title: 'new commodity', heading: { type: 'heading', id: heading.id, attributes: heading.attributes } }
    let(:commodity_search_reference) { build :commodity_search_reference, title:, referenced: commodity.attributes }

    specify do
      stub_api_for(Commodity) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}") do |_env|
          jsonapi_success_response('commodity', commodity.attributes)
        end
      end

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      refute search_reference_created_for(commodity, title:)

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.post("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          api_created_response
        end

        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [commodity_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      create_search_reference_for commodity, 'Reference' => title

      verify search_reference_created_for(commodity, title:)
    end
  end

  describe 'Search Reference deletion' do
    let(:commodity)                  { build :commodity, :with_heading, heading: { type: 'heading', id: heading.id, attributes: heading.attributes } }
    let(:commodity_search_reference) { build :commodity_search_reference, referenced: commodity.attributes }

    specify do
      stub_api_for(Commodity) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}") do |_env|
          jsonapi_success_response('commodity', commodity.attributes)
        end
      end

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [commodity_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      verify search_reference_created_for(commodity, title: commodity_search_reference[:title])

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', commodity_search_reference.attributes)
        end
        stub.delete("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}") do |_env|
          api_no_content_response
        end
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      remove_commodity_search_reference_for(commodity, commodity_search_reference)

      refute search_reference_created_for(commodity, title: commodity_search_reference[:title])
    end
  end

  describe 'Search reference editing' do
    let(:commodity)                  { build :commodity, :with_heading, heading: { type: 'heading', id: heading.id, attributes: heading.attributes } }
    let(:commodity_search_reference) { build :commodity_search_reference, referenced: commodity.attributes }
    let(:new_title) { 'new title' }

    specify do
      stub_api_for(Commodity) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}") do |_env|
          jsonapi_success_response('commodity', commodity.attributes)
        end
      end

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [commodity_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      verify search_reference_created_for(commodity, title: commodity_search_reference[:title])

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', commodity_search_reference.attributes)
        end
        stub.patch("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}") do |_env|
          api_no_content_response
        end
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [commodity_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      update_commodity_search_reference_for(commodity, commodity_search_reference, 'Reference' => new_title)

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references/#{commodity_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', commodity_search_reference.attributes.merge(title: new_title))
        end
      end

      verify commodity_search_reference_updated_for(commodity, commodity_search_reference, title: new_title)
    end
  end

  private

  def create_search_reference_for(commodity, fields_and_values = {})
    ensure_on new_references_commodity_search_reference_path(commodity)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Create Search reference'
  end

  def update_commodity_search_reference_for(commodity, search_reference, fields_and_values = {})
    ensure_on edit_references_commodity_search_reference_path(commodity, search_reference)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Update Search reference'
  end

  def remove_commodity_search_reference_for(commodity, commodity_search_reference)
    ensure_on references_commodity_search_references_path(commodity)

    within(dom_id_selector(commodity_search_reference)) do
      click_link 'Remove'
    end
  end

  def commodity_search_reference_updated_for(commodity, search_reference, args = {})
    ensure_on edit_references_commodity_search_reference_path(commodity, search_reference)

    page.has_field?('Reference', with: args[:title])
  end

  def search_reference_created_for(commodity, attributes = {})
    ensure_on references_commodity_search_references_path(commodity)

    within('table') do
      page.has_content? attributes.fetch(:title)
    end
  end
end
