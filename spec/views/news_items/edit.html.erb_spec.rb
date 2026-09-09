RSpec.describe "news_items/edit" do
  subject(:rendered_page) { render && rendered }

  before do
    assign :news_item, news_item
    assign :collections, []
    view.extend Pundit::Authorization
    allow(view).to receive(:current_user).and_return(current_user)
  end

  let(:current_user) { create(:user, :technical_operator) }
  let(:news_item) { build :news_item }

  it "renders the form" do
    expect(rendered_page).to include "Edit News story"
  end

  describe "remove section" do
    it "renders the remove section heading" do
      expect(rendered_page).to include "Remove this News item"
    end

    it "renders a form with a DELETE method input", :aggregate_failures do
      page = Capybara.string(rendered_page)
      remove_button = page.find "button", text: "Remove"
      form = remove_button.find :xpath, "./ancestor::form[1]"

      expect(form["method"]).to eq("post")
      expect(form).to have_css "input[name='_method'][value='delete']", visible: false
    end

    it "includes turbo_confirm data attribute with specific message", :aggregate_failures do
      expect(rendered_page).to include "data-turbo-confirm"
      expect(rendered_page).to include "Are you sure you want to remove this news item?"
    end

    it "includes turbo_submits_with data attribute for loading state", :aggregate_failures do
      expect(rendered_page).to include "data-turbo-submits-with"
      expect(rendered_page).to include "Working..."
    end

    it "renders button with warning styling" do
      page = Capybara.string(rendered_page)
      expect(page).to have_button "Remove", class: "govuk-button--warning"
    end

    it "posts to the correct news_item path", :aggregate_failures do
      page = Capybara.string(rendered_page)
      remove_button = page.find "button", text: "Remove"
      form = remove_button.find :xpath, "./ancestor::form[1]"

      expect(form["action"]).to include "/news_items/"
      expect(form["action"]).to end_with "/#{news_item.id}"
    end
  end
end
