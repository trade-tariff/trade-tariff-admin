require 'rails_helper'

RSpec.describe FaradayMiddleware::ServiceUrls do
  subject(:response) { connection.get('http://foo') }

  before do
    stub_request(:get, expected_url)

    Thread.current[:service_choice] = choice
  end

  after do
    Thread.current[:service_choice] = nil
  end

  let(:connection) do
    Faraday.new do |conn|
      conn.use described_class
      conn.adapter Faraday.default_adapter
    end
  end

  context 'when the service choice is xi' do
    let(:choice) { 'xi' }
    let(:expected_url) { 'http://localhost:3019' }

    it { expect(response.env[:url].to_s).to eq(expected_url) }
  end

  context 'when the service choice is uk' do
    let(:choice) { 'uk' }
    let(:expected_url) { 'http://localhost:3018' }

    it { expect(response.env[:url].to_s).to eq(expected_url) }
  end

  context 'when the service choice is not set' do
    let(:choice) { nil }
    let(:expected_url) { 'http://localhost:3018' }

    it { expect(response.env[:url].to_s).to eq(expected_url) }
  end
end
