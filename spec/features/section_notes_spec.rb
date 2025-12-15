# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Section Note management" do
  # rubocop:disable RSpec/LetSetup
  let!(:user) { create :user, :gds_editor }
  # rubocop:enable RSpec/LetSetup
  let(:section_note) { build :section_note }
  let(:section)      { build :section, title: "new section" }

  describe "Section Note creation" do
    before do
      stub_api_request("/admin/sections/#{section.id}")
        .to_return jsonapi_success_response("section", section.attributes)

      stub_api_request("/admin/sections/#{section.id}/section_note", :post)
        .to_return api_created_response

      stub_api_request("/admin/sections")
        .to_return jsonapi_success_response("section", [section.attributes])
    end

    specify do
      ensure_on new_notes_section_section_note_path(section)
      fill_in "Content", with: section_note.content
      click_button "Create Section note"
      verify current_path == root_path
    end
  end

  describe "section Note editing" do
    let(:section)      { build :section, :with_note }
    let(:section_note) { build :section_note, section_id: section.id }
    let(:new_content)  { "new content" }

    before do
      stub_api_request("/admin/sections/#{section.id}")
        .to_return jsonapi_success_response("section", section.attributes)

      stub_api_request("/admin/sections/#{section.id}/section_note", :patch)
        .to_return api_no_content_response

      stub_api_request("/admin/sections")
        .to_return jsonapi_success_response("section", [section.attributes])
    end

    specify do
      ensure_on edit_notes_section_section_note_path(section)
      fill_in "Content", with: "new content"
      click_button "Update Section note"
      verify current_path == root_path
    end
  end

  describe "Section Note deletion" do
    let(:section) { build :section, :with_note }

    before do
      stub_api_request("/admin/sections/#{section.id}")
        .to_return jsonapi_success_response("section", section.attributes)

      stub_api_request("/admin/sections/#{section.id}/section_note", :delete)
        .to_return api_no_content_response

      stub_api_request("/admin/sections")
        .to_return jsonapi_success_response("section", [section.attributes])
    end

    it "can be removed" do
      ensure_on edit_notes_section_section_note_path(section)
      click_link "Remove"
      verify current_path == root_path
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
