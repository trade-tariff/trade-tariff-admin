require 'rails_helper'

RSpec.describe 'Section Note management' do
  let!(:user) { create :user, :gds_editor }

  before do
    # section note specs do not concern chapters
    stub_api_for(Chapter) do |stub|
      stub.get('/admin/chapters') do |_env|
        api_success_response([])
      end
    end
  end

  describe 'Section Note creation' do
    let(:section_note) { build :section_note }
    let(:section)      { build :section, title: 'new section' }

    specify do
      stub_api_for(Section) do |stub|
        stub.get('/admin/sections') do |_env|
          jsonapi_success_response('section', [section.attributes])
        end
        stub.get("/admin/sections/#{section.id}") do |_env|
          jsonapi_success_response('section', section.attributes)
        end
      end

      stub_api_for(SectionNote) do |stub|
        stub.post("/admin/sections/#{section.id}/section_note") { |_env| api_created_response }
      end

      refute note_created_for(section)

      stub_api_for(Section) do |stub|
        stub.get('/admin/sections') { |_env| jsonapi_success_response('section', [section.attributes.merge(section_note_id: section_note.id)]) }
        stub.get("/admin/sections/#{section.id}") do |_env|
          jsonapi_success_response('section', section.attributes.merge(section_note_id: section_note.id))
        end
      end

      create_note_for section, content: section_note.content

      verify note_created_for(section)
    end
  end

  describe 'section Note editing' do
    let(:section)      { build :section, :with_note }
    let(:section_note) { build :section_note, section_id: section.id }
    let(:new_content)  { 'new content' }

    specify do
      stub_api_for(Section) do |stub|
        stub.get('/admin/sections') { |_env| jsonapi_success_response('section', [section.attributes]) }
        stub.get("/admin/sections/#{section.id}") { |_env| jsonapi_success_response('section', section.attributes) }
      end

      verify note_created_for(section)

      stub_api_for(SectionNote) do |stub|
        stub.get("/admin/sections/#{section.id}/section_note") { |_env| jsonapi_success_response('section_note', section_note.attributes) }
        stub.patch("/admin/sections/#{section.id}/section_note") { |_env| api_no_content_response }
      end

      update_note_for section, content: new_content

      stub_api_for(SectionNote) do |stub|
        stub.get("/admin/sections/#{section.id}/section_note") { |_env| jsonapi_success_response('section_note', section_note.attributes.merge(content: new_content)) }
      end

      verify note_updated_for(section, content: new_content)
    end
  end

  describe 'Section Note deletion' do
    let(:section)      { build :section, :with_note }
    let(:section_note) { build :section_note, section_id: section.id }

    it 'can be removed' do
      stub_api_for(Section) do |stub|
        stub.get('/admin/sections') { |_env| jsonapi_success_response('section', [section.attributes]) }
        stub.get("/admin/sections/#{section.id}") { |_env| jsonapi_success_response('section', section.attributes) }
      end

      stub_api_for(SectionNote) do |stub|
        stub.get("/admin/sections/#{section.id}/section_note") { |_env| jsonapi_success_response('section_note', section_note.attributes) }
        stub.delete("/admin/sections/#{section.id}/section_note") { |_env| api_no_content_response }
      end

      verify note_created_for(section)

      stub_api_for(Section) do |stub|
        stub.get('/admin/sections') { |_env| jsonapi_success_response('section', [section.attributes.except(:section_note_id)]) }
        stub.get("/admin/sections/#{section.id}") { |_env| jsonapi_success_response('section', section.attributes.except(:section_note_id)) }
      end

      remove_note_for section

      refute note_created_for(section)
    end
  end

  private

  def create_note_for(section, fields_and_values = {})
    ensure_on new_notes_section_section_note_path(section)

    fields_and_values.each do |field, value|
      fill_in "section_note_#{field}", with: value
    end

    yield if block_given?

    click_button 'Create Section note'
  end

  def update_note_for(section, fields_and_values = {})
    ensure_on edit_notes_section_section_note_path(section)

    fields_and_values.each do |field, value|
      fill_in "section_note_#{field}", with: value
    end

    yield if block_given?

    click_button 'Update Section note'
  end

  def note_updated_for(section, args = {})
    ensure_on edit_notes_section_section_note_path(section)

    page.has_field?('section_note_content', with: args[:content])
  end

  def note_created_for(section)
    ensure_on root_path

    page.has_selector?(dom_id_selector(section)) && (
      within(dom_id_selector(section)) do
        page.has_link?('Edit')
      end
    )
  end

  def remove_note_for(section)
    ensure_on edit_notes_section_section_note_path(section)

    click_link 'Remove'
  end
end
