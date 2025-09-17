require "rails_helper"
require "gds-sso/lint/user_spec"

RSpec.describe User do
  describe "gds-sso" do
    it_behaves_like "a gds-sso user class"
  end

  describe "#hmrc_admin" do
    context "when user has hmrc admin access" do
      let!(:user) { create :user, :hmrc_admin }

      it { expect(user.hmrc_admin?).to be(true) }
    end

    context "when user does not have hmrc admin access" do
      let!(:user) { create :user }

      it { expect(user.hmrc_admin?).not_to be(true) }
    end
  end

  describe "#update" do
    let!(:user) { create :user }
    let(:attrs) do
      attributes_for :user
    end

    before do
      user.update!(attrs)
      user.reload
    end

    it "updates the user attributes", :aggregate_failures do
      expect(user.name).to eq(attrs[:name])
      expect(user.email).to eq(attrs[:email])
    end
  end

  describe "#create!" do
    describe "valid" do
      let(:attrs) do
        attributes_for :user
      end

      it {
        expect {
          described_class.create!(attrs)
        }.to change(described_class, :count).by(1)
      }
    end

    describe "invalid" do
      let!(:user) { create :user }
      let(:attrs) do
        attributes_for(:user).merge(
          id: user.id,
        )
      end

      it {
        expect {
          described_class.create!(attrs)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      }
    end
  end
end
