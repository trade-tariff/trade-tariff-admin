require 'rails_helper'

RSpec.describe Her::Middleware::RaiseError do
  let :conn do
    Faraday.new do |conn|
      conn.use described_class
      conn.adapter :test do |stub|
        stub.get('ok') { [200, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('bad-request') { [400, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('not-found') { [404, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('conflict') { [409, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('unprocessable-entity') { [422, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('html-response') { [422, { 'content-type' => 'text/html' }, 'something'] }
        stub.get('4xx') { [499, { 'content-type' => 'application/json' }, 'something'] }
        stub.get('nil-status') { [nil, { 'content-type' => 'application/json' }, 'fail'] }
        stub.get('server-error') { [500, { 'content-type' => 'application/json' }, 'fail'] }
      end
    end
  end

  context 'with success response' do
    it { expect { conn.get('ok') }.not_to raise_error }
  end

  context 'with bad request response' do
    it { expect { conn.get('bad-request') }.not_to raise_error }
  end

  context 'with conflict response' do
    it { expect { conn.get('conflict') }.not_to raise_error }
  end

  context 'with unprocessable entity response' do
    it { expect { conn.get('unprocessable-entity') }.not_to raise_error }
  end

  context 'with known 4xx response' do
    it { expect { conn.get('not-found') }.to raise_error Faraday::ResourceNotFound }
  end

  context 'with unknown 4xx response' do
    it { expect { conn.get('4xx') }.to raise_error Faraday::ClientError }
  end

  context 'with 5xx response' do
    it { expect { conn.get('server-error') }.to raise_error Faraday::ServerError }
  end

  context 'with non json response' do
    it { expect { conn.get('html-response') }.to raise_error Faraday::UnprocessableEntityError }
  end
end
