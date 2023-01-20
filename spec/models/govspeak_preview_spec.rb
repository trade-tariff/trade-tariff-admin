require 'rails_helper'

RSpec.describe GovspeakPreview do
  subject(:preview) { described_class.new content }

  let :content do
    <<~EOCONTENT
      # Heading

      This is content for [[SERVICE_NAME]]

      This is a <a href="/" target="_blank">link</a>
    EOCONTENT
  end

  describe '#render' do
    subject(:rendered) { preview.render }

    include_context 'with UK service'

    it 'converts markdown' do
      expect(rendered).to match '<h1 id="heading">Heading</h1>'
    end

    it 'replaces service tags' do
      expect(rendered).to match 'content for UK'
    end

    it 'supports links to new windows' do
      expect(rendered).to match '<a href="/" target="_blank">link</a>'
    end
  end
end
