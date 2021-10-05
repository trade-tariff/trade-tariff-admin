require 'rails_helper'

RSpec.describe 'Rollbacks management' do
  let!(:user) { create :user, :gds_editor }

  describe 'Rollback creation' do
    let(:rollback) { build :rollback, user: user }

    specify do
      stub_api_for(Rollback) do |stub|
        stub.get('/admin/rollbacks') do |_env|
          api_success_response(data: [], meta: { pagination: pagination_params })
        end
      end

      refute rollback_created(rollback)

      stub_api_for(Rollback) do |stub|
        stub.post('/admin/rollbacks') do |_env|
          api_created_response
        end

        stub.get('/admin/rollbacks') do |_env|
          api_success_response(
            data: [{ type: 'rollback', attributes: rollback.attributes }],
            meta: { pagination: pagination_params(total_count: 1) },
          )
        end
      end

      create_rollback(rollback)

      verify rollback_created(rollback)
    end
  end

  private

  def rollback_created(rollback)
    ensure_on rollbacks_path

    page.has_selector?('table.rollbacks') &&
      page.has_content?(rollback.date)
  end

  def create_rollback(rollback)
    ensure_on new_rollback_path

    fill_in 'rollback_date', with: rollback.date

    click_button 'Create Rollback'
  end
end
