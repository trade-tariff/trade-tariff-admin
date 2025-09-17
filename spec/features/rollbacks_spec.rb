require "rails_helper"

# rubocop:disable RSpec/NoExpectationExample
RSpec.describe "Rollbacks management" do
  let!(:user) { create :user, :hmrc_admin }

  describe "Rollback creation" do
    let(:rollback) { build :rollback, user_id: user.id }

    before do
      stub_api_request("/admin/rollbacks")
        .to_return api_success_response(
          data: [],
          meta: { pagination: pagination_params },
        )

      stub_api_request("/admin/rollbacks", :post)
        .to_return api_created_response
    end

    specify do
      ensure_on new_rollback_path

      fill_in "Reason", with: "a reason"
      fill_in "Rollback to", with: rollback.date
      click_button "Create Rollback"

      verify current_path == rollbacks_path
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
