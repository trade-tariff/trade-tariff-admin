RSpec.describe "live_issues/edit" do
  subject(:rendered_page) { render && rendered }

  before do
    assign :live_issue, live_issue
    view.extend Pundit::Authorization
    allow(view).to receive(:current_user).and_return(current_user)
  end

  let(:current_user) { create(:user, :technical_operator) }
  let(:live_issue) { build :live_issue }

  it "renders the form" do
    expect(rendered_page).to include "Update Live Issue"
  end

  describe "remove section" do
    it "renders the remove section heading" do
      expect(rendered_page).to include "Remove this Live Issue"
    end

    it "renders a form with a DELETE method input", :aggregate_failures do
      page = Capybara.string(rendered_page)
      remove_button = page.find "button", text: "Remove"
      form = remove_button.find :xpath, "./ancestor::form[1]"

      expect(form["method"]).to eq("post")
      expect(form).to have_css "input[name='_method'][value='delete']", visible: false
    end

    it "includes turbo_confirm data attribute with custom message", :aggregate_failures do
      expect(rendered_page).to include "data-turbo-confirm"
      expect(rendered_page).to include "Are you sure you want to remove this live issue?"
    end

    it "includes turbo_submits_with data attribute for loading state", :aggregate_failures do
      expect(rendered_page).to include "data-turbo-submits-with"
      expect(rendered_page).to include "Working..."
    end

    it "renders button with warning styling" do
      page = Capybara.string(rendered_page)
      expect(page).to have_button "Remove", class: "govuk-button--warning"
    end

    it "posts to the correct live_issue path", :aggregate_failures do
      page = Capybara.string(rendered_page)
      remove_button = page.find "button", text: "Remove"
      form = remove_button.find :xpath, "./ancestor::form[1]"

      expect(form["action"]).to include "/live_issues/"
      expect(form["action"]).to end_with "/#{live_issue.id}"
    end
  end
end
