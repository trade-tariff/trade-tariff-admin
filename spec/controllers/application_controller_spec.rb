RSpec.describe ApplicationController do
  controller do
    def index
      render plain: "ok"
    end
  end

  describe "#default_landing_path" do
    context "when user is hmrc_admin" do
      let(:user) { create(:user, :hmrc_admin) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns references_sections_path" do
        expect(controller.default_landing_path).to eq(references_sections_path)
      end
    end

    context "when user is technical_operator" do
      let(:user) { create(:user, :technical_operator) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns root_path" do
        expect(controller.default_landing_path).to eq(root_path)
      end
    end

    context "when user is auditor" do
      let(:user) { create(:user, :auditor) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns root_path" do
        expect(controller.default_landing_path).to eq(root_path)
      end
    end

    context "when user is guest" do
      let(:user) { create(:user, :guest) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns root_path" do
        expect(controller.default_landing_path).to eq(root_path)
      end
    end

    context "when user is nil" do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it "returns root_path" do
        expect(controller.default_landing_path).to eq(root_path)
      end
    end
  end
end
