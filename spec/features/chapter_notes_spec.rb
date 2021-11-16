require 'rails_helper'

RSpec.describe 'Chapter Note management' do
  let!(:user) { create :user, :gds_editor }

  before do
    # chapter note specs do not concern sections
    stub_api_for(Section) do |stub|
      stub.get('/admin/sections') do |_env|
        jsonapi_success_response('section', [])
      end
    end
  end

  describe 'Chapter Note creation' do
    let(:section)      { build :section }
    let(:chapter_note) { build :chapter_note }
    let(:chapter)      { build :chapter, :with_section, title: 'new chapter', section: { type: 'section', id: section.id, attributes: section.attributes } }

    specify do
      stub_api_for(Chapter) do |stub|
        stub.get("/admin/sections/#{section.id}/chapters") do |_env|
          jsonapi_success_response('chapter', [chapter.attributes])
        end
        stub.get("/admin/chapters/#{chapter.to_param}") do |_env|
          jsonapi_success_response('chapter', chapter.attributes)
        end
      end

      stub_api_for(ChapterNote) do |stub|
        stub.post("/admin/chapters/#{chapter.to_param}/chapter_note") { |_env| api_created_response }
      end

      stub_api_for(Section) do |stub|
        stub.get("/admin/sections/#{section.id}") do |_env|
          jsonapi_success_response('section', section.attributes)
        end
      end

      refute note_created_for(chapter)

      stub_api_for(Chapter) do |stub|
        stub.get("/admin/sections/#{section.id}/chapters") do |_env|
          jsonapi_success_response('chapter', [chapter.attributes.merge(chapter_note_id: 1)])
        end
        stub.get("/admin/chapters/#{chapter.to_param}") do |_env|
          jsonapi_success_response('chapter', chapter.attributes)
        end
      end

      create_note_for chapter, 'Content' => chapter_note.content

      verify note_created_for(chapter)
    end
  end

  describe 'chapter Note editing' do
    let(:section)      { build :section }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: { type: 'section', id: section.id, attributes: section.attributes } }
    let(:chapter_note) { build :chapter_note, :persisted, chapter_id: chapter.to_param }
    let(:new_content)  { 'new content' }

    specify do
      stub_api_for(Chapter) do |stub|
        stub.get("/admin/sections/#{section.id}/chapters") do |_env|
          jsonapi_success_response('chapter', [chapter.attributes])
        end
        stub.get("/admin/chapters/#{chapter.to_param}") do |_env|
          jsonapi_success_response('chapter', chapter.attributes)
        end
      end

      stub_api_for(Section) do |stub|
        stub.get("/admin/sections/#{section.id}") do |_env|
          jsonapi_success_response('section', section.attributes)
        end
      end

      stub_api_for(ChapterNote) do |stub|
        stub.get("/admin/chapters/#{chapter.to_param}/chapter_note") do |_env|
          jsonapi_success_response('chapter_note', chapter_note.attributes)
        end

        stub.patch("/admin/chapters/#{chapter.to_param}/chapter_note") do |_env|
          api_no_content_response
        end
      end

      verify note_created_for(chapter)

      update_note_for chapter, 'Content' => new_content

      stub_api_for(ChapterNote) do |stub|
        stub.get("/admin/chapters/#{chapter.to_param}/chapter_note") do |_env|
          jsonapi_success_response('chapter_note', chapter_note.attributes.merge(content: new_content))
        end
      end

      verify note_updated_for(chapter, content: new_content)
    end
  end

  describe 'Chapter Note deletion' do
    let(:section)      { build :section }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: { type: 'section', id: section.id, attributes: section.attributes } }
    let(:chapter_note) { build :chapter_note, :persisted, chapter_id: chapter.to_param }

    specify do
      stub_api_for(Section) do |stub|
        stub.get("/admin/sections/#{section.id}") do |_env|
          jsonapi_success_response('section', section.attributes)
        end
      end

      stub_api_for(Chapter) do |stub|
        stub.get("/admin/sections/#{section.id}/chapters") do |_env|
          jsonapi_success_response('chapter', [chapter.attributes])
        end
        stub.get("/admin/chapters/#{chapter.to_param}") do |_env|
          jsonapi_success_response('chapter', chapter.attributes)
        end
      end

      stub_api_for(ChapterNote) do |stub|
        stub.get("/admin/chapters/#{chapter.to_param}/chapter_note") { |_env| jsonapi_success_response('chapter_note', chapter_note.attributes) }
        stub.delete("/admin/chapters/#{chapter.to_param}/chapter_note") { |_env| api_no_content_response }
      end

      verify note_created_for(chapter)

      stub_api_for(Chapter) do |stub|
        stub.get("/admin/sections/#{section.id}/chapters") do |_env|
          jsonapi_success_response('chapter', [chapter.attributes.except(:chapter_note_id)])
        end
        stub.get("/admin/chapters/#{chapter.to_param}") do |_env|
          jsonapi_success_response('chapter', chapter.attributes.except(:chapter_note_id))
        end
      end

      remove_note_for chapter

      refute note_created_for(chapter)
    end
  end

  private

  def create_note_for(chapter, fields_and_values = {})
    ensure_on new_notes_chapter_chapter_note_path(chapter)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Create Chapter note'
  end

  def update_note_for(chapter, fields_and_values = {})
    ensure_on edit_notes_chapter_chapter_note_path(chapter)

    fields_and_values.each do |field, value|
      fill_in field, with: value
    end

    yield if block_given?

    click_button 'Update Chapter note'
  end

  def note_updated_for(chapter, args = {})
    ensure_on edit_notes_chapter_chapter_note_path(chapter)

    page.has_field?('Content', with: args[:content])
  end

  def note_created_for(chapter)
    ensure_on notes_section_chapters_path(section_id: chapter.section[:id])

    page.has_selector?(dom_id_selector(chapter)) && (
      within(dom_id_selector(chapter)) do
        page.has_link?('Edit')
      end
    )
  end

  def remove_note_for(chapter)
    ensure_on edit_notes_chapter_chapter_note_path(chapter)

    click_link 'Remove'
  end
end
