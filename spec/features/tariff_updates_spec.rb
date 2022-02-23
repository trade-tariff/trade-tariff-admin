require 'rails_helper'

RSpec.describe 'Tariff Update listing' do
  let!(:user) { create :user, :gds_editor }
  let(:tariff_update) { attributes_for(:tariff_update, :cds, :failed, :with_exception) }

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

    expect(page).to have_content 'Cds'
    expect(page).to have_content 'Failed'
    expect(page).to have_content 'CdsImporter::ImportException'
    expect(page).to have_content 'logger_spec.rb:179'
    expect(page).to have_content '(Sequel::Mysql2::Database)'
  end
end
