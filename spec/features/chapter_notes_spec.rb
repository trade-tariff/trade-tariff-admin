RSpec.describe "Chapter Note management" do
  before { create :user, :technical_operator }

  describe "Chapter Note creation" do
    let(:section) { build :section, resource_id: 1 }
    let(:chapter) do
      build(
        :chapter,
        :with_section,
        title: "new chapter",
        section: section.attributes.merge(resource_id: section.resource_id),
      )
    end

    before do
      stub_api_request("/admin/chapters/#{chapter.id}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.id}/chapter_note", :post)
        .to_return api_created_response

      stub_api_request("/admin/sections/#{section.id}/chapters")
        .to_return jsonapi_success_response("chapter", [chapter.attributes])
    end

    specify do
      ensure_on new_notes_chapter_chapter_note_path(chapter)
      fill_in "Content", with: "new content"
      click_button "Create Chapter note"
      expect(current_path == notes_section_chapters_path(section_id: chapter.section.id)).to be_truthy
    end
  end

  describe "chapter Note editing" do
    let(:section)      { build :section, resource_id: 1 }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: section.attributes.merge(resource_id: section.resource_id) }

    before do
      stub_api_request("/admin/chapters/#{chapter.id}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.id}/chapter_note", :patch)
        .to_return api_no_content_response

      stub_api_request("/admin/sections/#{section.id}/chapters")
        .to_return jsonapi_success_response("chapter", [chapter.attributes])
    end

    specify do
      ensure_on edit_notes_chapter_chapter_note_path(chapter)
      fill_in "Content", with: "new content"
      click_button "Update Chapter note"
      expect(current_path == notes_section_chapters_path(section_id: chapter.section.id)).to be_truthy
    end
  end

  describe "Chapter Note deletion" do
    let(:section)      { build :section, resource_id: 1 }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: section.attributes.merge(resource_id: section.resource_id) }

    before do
      stub_api_request("/admin/chapters/#{chapter.id}")
        .to_return jsonapi_success_response("chapter", chapter.attributes)

      stub_api_request("/admin/chapters/#{chapter.id}/chapter_note", :delete)
        .to_return api_no_content_response

      stub_api_request("/admin/sections/#{section.id}/chapters")
        .to_return jsonapi_success_response("chapter", [chapter.attributes])
    end

    specify do
      ensure_on edit_notes_chapter_chapter_note_path(chapter)
      click_link "Remove"
      expect(current_path == notes_section_chapters_path(section_id: chapter.section.id)).to be_truthy
    end
  end
end
