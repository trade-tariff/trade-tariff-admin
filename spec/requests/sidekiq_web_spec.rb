require "rails_helper"

RSpec.describe "Sidekiq Web", type: :request do
  let(:uk_sidekiq_env) { {} }
  let(:xi_sidekiq_env) { {} }

  before do
    allow(UkSidekiqWeb).to receive(:call) do |env|
      uk_sidekiq_env.merge!(env)
      [200, { "content-type" => "text/plain" }, ["UK Sidekiq Web"]]
    end
    allow(XiSidekiqWeb).to receive(:call) do |env|
      xi_sidekiq_env.merge!(env)
      [200, { "content-type" => "text/plain" }, ["XI Sidekiq Web"]]
    end
  end

  context "when the user is a technical operator" do
    it "shows the UK Sidekiq Web", :aggregate_failures do
      get "/sidekiq/uk"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("UK Sidekiq Web")
    end

    it "shows the XI Sidekiq Web", :aggregate_failures do
      get "/sidekiq/xi"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("XI Sidekiq Web")
    end

    it "passes the UK root as the root path of the UK app", :aggregate_failures do
      get "/sidekiq/uk"

      expect(uk_sidekiq_env["SCRIPT_NAME"]).to eq("/sidekiq/uk")
      expect(uk_sidekiq_env["PATH_INFO"]).to eq("/")
    end

    it "passes nested UK paths to the UK app", :aggregate_failures do
      get "/sidekiq/uk/queues"

      expect(response.body).to eq("UK Sidekiq Web")
      expect(uk_sidekiq_env["SCRIPT_NAME"]).to eq("/sidekiq/uk")
      expect(uk_sidekiq_env["PATH_INFO"]).to eq("/queues")
    end

    it "passes nested XI paths to the XI app with the XI script name", :aggregate_failures do
      get "/sidekiq/xi/retries"

      expect(response.body).to eq("XI Sidekiq Web")
      expect(xi_sidekiq_env["SCRIPT_NAME"]).to eq("/sidekiq/xi")
      expect(xi_sidekiq_env["PATH_INFO"]).to eq("/retries")
    end

    it "redirects /sidekiq to the UK Sidekiq Web" do
      get "/sidekiq"

      expect(response).to redirect_to("/sidekiq/uk")
    end
  end

  context "when the user is a superadmin" do
    let(:current_user) { create(:user, :superadmin) }

    it "shows the UK Sidekiq Web" do
      get "/sidekiq/uk"

      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is an hmrc admin" do
    let(:current_user) { create(:user, :hmrc_admin) }

    it "returns not found for the UK Sidekiq Web", :aggregate_failures do
      get "/sidekiq/uk"

      expect(response).to have_http_status(:not_found)
      expect(UkSidekiqWeb).not_to have_received(:call)
    end

    it "returns not found for the XI Sidekiq Web", :aggregate_failures do
      get "/sidekiq/xi"

      expect(response).to have_http_status(:not_found)
      expect(XiSidekiqWeb).not_to have_received(:call)
    end
  end

  context "when the user is not signed in" do
    let(:authenticate_user) { false }

    it "returns not found for /sidekiq" do
      get "/sidekiq"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for the UK Sidekiq Web", :aggregate_failures do
      get "/sidekiq/uk"

      expect(response).to have_http_status(:not_found)
      expect(UkSidekiqWeb).not_to have_received(:call)
    end

    it "returns not found for a POST to the XI Sidekiq Web", :aggregate_failures do
      post "/sidekiq/xi/retries/all/delete"

      expect(response).to have_http_status(:not_found)
      expect(XiSidekiqWeb).not_to have_received(:call)
    end
  end
end
