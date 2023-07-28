require 'rails_helper'

RSpec.describe HealthcheckController do
  it 'returns success on request' do
    get :check
    expect(response.status).to eq(200)
  end

  it 'returns success for container' do
    get :checkz
    expect(response.status).to eq(200)
  end
end
