require 'rails_helper'

RSpec.describe 'Footnote management' do
  let!(:user) { create :user, :gds_editor }

  describe 'Footnote editing' do
    let(:footnote)         { build :footnote }
    let(:new_description)  { 'new content' }

    specify do
      stub_api_for(Footnote) do |stub|
        stub.get('/admin/footnotes') do |_env|
          api_success_response(data: [{ type: 'footnote', id: footnote.id, attributes: footnote.attributes }])
        end
        stub.get("/admin/footnotes/#{footnote.to_param}") do |_env|
          api_success_response(data: { type: 'footnote', id: footnote.id,  attributes: footnote.attributes })
        end
        stub.patch("/admin/footnotes/#{footnote.to_param}") do |_env|
          api_no_content_response
        end
      end

      verify footnote_created(footnote)

      update_footnote_for footnote, description: new_description

      stub_api_for(Footnote) do |stub|
        stub.get("/admin/footnotes/#{footnote.to_param}") do |_env|
          api_success_response(data: { type: 'footnote', id: footnote.id, attributes: footnote.attributes.merge(description: new_description) })
        end
      end

      verify footnote_updated(footnote, description: new_description)
    end
  end

  private

  def update_footnote_for(footnote, fields_and_values = {})
    ensure_on edit_footnote_path(footnote)

    fields_and_values.each do |field, value|
      fill_in "footnote_#{field}", with: value
    end

    yield if block_given?

    click_button 'Update Footnote'
  end

  def footnote_updated(footnote, args = {})
    ensure_on edit_footnote_path(footnote)

    page.has_field?('footnote_description', with: args[:description])
  end

  def footnote_created(footnote)
    ensure_on footnotes_path

    page.has_content? footnote.id
  end
end
