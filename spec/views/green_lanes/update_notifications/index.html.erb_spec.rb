RSpec.describe "green_lanes/update_notifications/index" do
  subject(:rendered_page) { render && rendered }

  before do
    assign :updates, updates
    view.extend Pundit::Authorization
    allow(view).to receive_messages(current_user:, paginate: nil)
  end

  let(:updates) { [build(:update_notification, status: "active")] }

  context "when user is a technical operator" do
    let(:current_user) { create(:user, :technical_operator) }

    it "shows edit links" do
      expect(rendered_page).to have_link "Edit"
    end
  end

  context "when user is an auditor" do
    let(:current_user) { create(:user, :auditor) }

    it "hides edit links" do
      expect(rendered_page).not_to have_link "Edit"
    end
  end
end
