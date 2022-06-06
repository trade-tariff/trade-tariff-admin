require 'rails_helper'

RSpec.describe References::Commodities::SearchReferencesController do
  subject(:rendered) { create_user && make_request && response }

  let(:create_user) { create(:user, :hmrc_editor) }

  describe 'POST #export' do
    let(:make_request) { post export_references_commodity_search_references_path(commodity_id) }
    let(:commodity) { build(:commodity, id: commodity_id) }
    let(:commodity_id) { '0101210000-80' }
    let(:commodity_search_reference) { build :commodity_search_reference, title: 'Blips and Chitz', referenced: commodity.attributes }

    before do
      allow(SearchReference::ExportService).to receive(:new).and_call_original

      stub_api_for(Commodity) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}") do |_env|
          jsonapi_success_response('commodity', commodity.attributes)
        end
      end

      stub_api_for(Commodity::SearchReference) do |stub|
        stub.get("/admin/commodities/#{commodity.to_param}/search_references") do |_env|
          jsonapi_success_response('search_reference', [commodity_search_reference.attributes], {})
        end
      end
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: 'text/csv' }

    it 'initializes the ExportService with the correct args' do
      rendered

      expect(SearchReference::ExportService).to have_received(:new)
    end
  end
end
