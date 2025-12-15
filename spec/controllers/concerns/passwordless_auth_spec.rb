RSpec.describe PasswordlessAuth, type: :controller do
  controller(ApplicationController) do
    include PasswordlessAuth # rubocop:disable RSpec/DescribedClass

    def index
      render plain: "ok"
    end
  end

  before do
    routes.draw { get "passwordless", to: "anonymous#index" }
    allow(TradeTariffAdmin).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")
  end

  it "redirects to the identity service when unauthenticated" do
    get :index

    expect(response).to redirect_to("http://identity.example.com/admin")
  end

  it "allows the request when the session is valid" do
    allow(Session).to receive(:find_by).and_return(instance_double(Session, renew?: false, user: build(:user)))

    get :index

    expect(response).to be_successful
  end
end
