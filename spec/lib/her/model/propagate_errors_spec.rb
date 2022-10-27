require 'rails_helper'

RSpec.describe Her::Model::PropagateErrors do
  let :her_model do
    Class.new do
      # has to be defined before including Her
      def self.name
        'MockEntity'
      end

      include Her::JsonApi::Model

      collection_path '/admin/mock_entities'

      attributes :name, :age
    end
  end

  describe '#save' do
    subject { her_model.new.save }

    context 'when successful' do
      before do
        stub_api_request('/mock_entities', :post).and_return webmock_response(:created)
      end

      it { is_expected.to be_instance_of her_model }
    end

    context 'when not successful' do
      before do
        stub_api_request('/mock_entities', :post).and_return \
          webmock_response(:error, name: 'cannot be blank')
      end

      it { is_expected.to be false }
    end
  end

  describe '#errors' do
    subject { her_model.new.tap(&:save).errors.messages }

    context 'without errors' do
      before do
        stub_api_request('/mock_entities', :post).and_return webmock_response(:created)
      end

      it { is_expected.to be_empty }
    end

    context 'with errors' do
      before do
        stub_api_request('/mock_entities', :post).and_return \
          webmock_response(:error, name: 'cannot be blank', age: 'must be over 18')
      end

      it { is_expected.to include name: ['Name cannot be blank'] }
      it { is_expected.to include age: ['Age must be over 18'] }

      context 'with renamed attribute' do
        before do
          allow(her_model).to receive(:human_attribute_name).and_call_original
          allow(her_model).to receive(:human_attribute_name).with('name')
                                                            .and_return('Full name')
        end

        it { is_expected.to include name: ['Full name cannot be blank'] }
      end
    end
  end
end
