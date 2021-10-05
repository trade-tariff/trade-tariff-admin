require 'rails_helper'

RSpec.describe 'Tariff Update listing' do
  let!(:user) { create :user, :gds_editor }
  let(:tariff_update) { attributes_for(:tariff_update, :chief, :missing, :with_exception) }

  before do
    stub_api_for(TariffUpdate) do |stub|
      stub.get('/admin/updates') do |_env|
        api_success_response(
          data: [{ type: 'tariff_update', attributes: tariff_update }],
          meta: { pagination: pagination_params(total_count: 1) },
        )
      end
    end
  end

  it 'lists all tariff updates' do
    visit tariff_updates_path

    expect(page).to have_content 'CHIEF'
    expect(page).to have_content 'Missing'
    expect(page).to have_content 'ChiefImporter::ImportException'
    expect(page).to have_content 'logger_spec.rb:179'
    expect(page).to have_content '(Sequel::Mysql2::Database)'
  end
end
