RSpec.describe References::SectionsController do
  include_context "with authenticated user"

  let(:section) { build(:section, title: "Live animals") }

  before do
    allow(controller).to receive_messages(authenticated?: true, current_user: current_user)
  end

  describe "GET #index" do
    it "returns the available sections", :aggregate_failures do
      allow(Section).to receive(:all).and_return([section])

      get :index

      expect(response).to have_http_status(:success)
      expect(assigns(:sections)).to eq([section])
    end
  end

  describe "#show" do
    before do
      allow(Section).to receive(:find).with(section.id.to_s).and_return(section)
      allow(controller).to receive_messages(
        authorize: nil,
        params: ActionController::Parameters.new(id: section.id.to_s),
        respond_with: nil,
      )
    end

    it "responds with the requested section" do
      controller.show

      expect(controller).to have_received(:respond_with).with(section)
    end
  end
end
