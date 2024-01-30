require 'rails_helper'

RSpec.describe References::ImportsController, type: :controller do
  describe 'GET #show' do
    subject(:rendered) { create_imports && make_request }
    let(:create_imports) { create_list(:import_task, 5) }
    let(:make_request) { get references_import_path }

    it { is_expected.to have_http_status :success }
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      subject(:rendered) { make_request }
      let(:make_request) { post references_import_path params: { import_task: { file: :import_task }}}

      it { is_expected.to have_http_status :success }
    end
  end
end
