require 'rails_helper'

RSpec.describe References::ImportsController do
  subject(:rendered) { create_user && make_request && response }

  let(:create_user) { create(:user, :hmrc_editor) }

  describe 'GET #show' do
    before do
      create_list(:import_task, 5)
    end

    let(:make_request) { get references_import_path }

    it { is_expected.to have_http_status :success }
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:make_request) do
        post references_import_path,
             params: {
               import_task: {
                 file: fixture_file_upload('search_references.csv', 'text/csv'),
               },
             }
      end

      it { is_expected.to have_http_status :redirect }
    end

    context 'without valid parameters' do
      let(:make_request) do
        post references_import_path,
             params: {
               import_task: {},
             }
      end

      it { is_expected.to have_http_status :redirect }
    end
  end
end
