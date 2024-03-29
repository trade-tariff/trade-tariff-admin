require 'rails_helper'
require 'search_reference'

RSpec.describe 'Heading Search Reference management' do
  let!(:user)   { create :user, :gds_editor }
  let(:chapter) { build :chapter }

  describe 'Search Reference creation' do
    let(:title)        { '  New    title ' }
    let(:heading)      { build :heading, chapter: { type: 'chapter', id: chapter.id, attributes: chapter.attributes } }
    let(:heading_search_reference) { build :heading_search_reference, title: 'new title', referenced: heading.attributes }

    specify do
      stub_api_for(Heading) do |stub|
        stub.get("/admin/headings/#{heading.to_param}") do |_env|
          jsonapi_success_response('heading', heading.attributes)
        end
      end

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      refute search_reference_created_for(heading, title: 'new title')

      stub_api_for(Heading::SearchReference) do |stub|
        stub.post("/admin/headings/#{heading.to_param}/search_references") do |env|
          expect(env.body.dig(:data, :attributes, :title)).to eq('new title')
          api_created_response
        end

        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [heading_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      create_search_reference_for heading, 'Search reference' => title

      verify search_reference_created_for(heading, title: 'new title')
    end
  end

  describe 'Search Reference deletion' do
    let(:heading)                  { build :heading, :with_chapter, chapter: { type: 'chapter', id: chapter.id, attributes: chapter.attributes } }
    let(:heading_search_reference) { build :heading_search_reference, referenced: heading.attributes }

    specify do
      stub_api_for(Heading) do |stub|
        stub.get("/admin/headings/#{heading.to_param}") do |_env|
          jsonapi_success_response('heading', heading.attributes)
        end
      end

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('heading', [heading_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      verify search_reference_created_for(heading, title: heading_search_reference[:title])

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', heading_search_reference.attributes)
        end
        stub.delete("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}") do |_env|
          api_no_content_response
        end
        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      remove_heading_search_reference_for(heading, heading_search_reference)

      refute search_reference_created_for(heading, title: heading_search_reference[:title])
    end
  end

  describe 'Search reference editing' do
    let(:heading)                  { build :heading, :with_chapter, chapter: { type: 'chapter', id: chapter.id, attributes: chapter.attributes } }
    let(:heading_search_reference) { build :heading_search_reference, referenced: heading.attributes }
    let(:new_title) { ' fLim   flam   ' }

    specify do
      stub_api_for(Heading) do |stub|
        stub.get("/admin/headings/#{heading.to_param}") do |_env|
          jsonapi_success_response('heading', heading.attributes)
        end
      end

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [heading_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      verify search_reference_created_for(heading, title: heading_search_reference[:title])

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', heading_search_reference.attributes)
        end
        stub.patch("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}") do |env|
          expect(env.body.dig(:data, :attributes, :title)).to eq('flim flam')
          api_no_content_response
        end
        stub.get("/admin/headings/#{heading.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [heading_search_reference.attributes], 'x-meta' => { pagination: { total: 1 } }.to_json)
        end
      end

      update_heading_search_reference_for(heading, heading_search_reference, 'Search reference' => 'flim flam')

      stub_api_for(Heading::SearchReference) do |stub|
        stub.get("/admin/headings/#{heading.to_param}/search_references/#{heading_search_reference.to_param}") do |_env|
          jsonapi_success_response('search_reference', heading_search_reference.attributes.merge(title: 'flim flam'))
        end
      end

      verify heading_search_reference_updated_for(heading, heading_search_reference, title: 'flim flam')
    end
  end

  private

  def create_search_reference_for(heading, fields_and_values = {})
    ensure_on new_references_heading_search_reference_path(heading)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Create Search reference'
  end

  def update_heading_search_reference_for(heading, search_reference, fields_and_values = {})
    ensure_on edit_references_heading_search_reference_path(heading, search_reference)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Update Search reference'
  end

  def remove_heading_search_reference_for(heading, heading_search_reference)
    ensure_on references_heading_search_references_path(heading)

    within(dom_id_selector(heading_search_reference)) do
      click_link 'Remove'
    end
  end

  def heading_search_reference_updated_for(heading, search_reference, args = {})
    ensure_on edit_references_heading_search_reference_path(heading, search_reference)

    page.has_field?('Search reference', with: args[:title])
  end

  def search_reference_created_for(heading, attributes = {})
    ensure_on references_heading_search_references_path(heading)

    page.has_content? attributes.fetch(:title)
  end
end
