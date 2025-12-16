# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Chapter Note management" do
  # rubocop:disable RSpec/LetSetup
  let!(:user) { create :user, :gds_editor }
  # rubocop:enable RSpec/LetSetup

  describe "Chapter Note creation" do
    let(:section) { build :section }
    let(:chapter) do
      build(
        :chapter,
        :with_section,
        title: "new chapter",
        section: {
          type: "section",
          id: section.id,
          attributes: section.attributes,
        },
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
      verify current_path == notes_section_chapters_path(section_id: chapter.section.id)
    end
  end

  describe "chapter Note editing" do
    let(:section)      { build :section }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: { type: "section", resource_id: section.id, attributes: section.attributes } }

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
      verify current_path == notes_section_chapters_path(section_id: chapter.section.id)
    end
  end

  describe "Chapter Note deletion" do
    let(:section)      { build :section }
    let(:chapter)      { build :chapter, :with_note, :with_section, section: { type: "section", id: section.id, attributes: section.attributes } }

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
      verify current_path == notes_section_chapters_path(section_id: chapter.section.id)
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
