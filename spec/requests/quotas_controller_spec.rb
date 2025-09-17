RSpec.describe QuotasController do
  describe "GET #new" do
    subject(:do_request) do
      create(:user, :hmrc_editor)

      get new_quota_path

      response
    end

    context "when on uk service" do
      include_context "with UK service"

      it { is_expected.to render_template(:new) }
    end

    context "when on xi service" do
      include_context "with XI service"

      it { is_expected.to render_template(:not_found) }
    end
  end

  describe "GET #search" do
    subject(:do_request) do
      create(:user, :hmrc_editor)

      today = Time.zone.today
      get perform_search_quotas_path(
        quota_search: {
          order_number: quota_definition.quota_order_number_id,
          'import_date(3i)': today.day.to_s,
          'import_date(2i)': today.month.to_s,
          'import_date(1i)': today.year.to_s,
        },
      )

      response
    end

    let(:quota_definitions) { [quota_definition, quota_definition] }
    let(:quota_definition) do
      build(
        :quota_definition,
        :with_quota_order_number,
        :with_quota_balance_events,
        :with_quota_order_number_origins,
        :without_quota_critical_events,
        :without_quota_unsuspension_events,
        :without_quota_exhaustion_events,
        :without_quota_reopening_events,
        :without_quota_unblocking_events,
      )
    end

    before do
      create(:user, :hmrc_editor)

      allow(QuotaOrderNumbers::QuotaDefinition).to receive(:all).and_return(quota_definitions)
    end

    context "when on uk service" do
      include_context "with UK service"

      it "fetches the quota definition" do
        do_request

        expect(QuotaOrderNumbers::QuotaDefinition).to have_received(:all).with(quota_order_number_id: quota_definition.quota_order_number_id, as_of: Time.zone.today.iso8601)
      end

      it { is_expected.to render_template(:search) }
    end

    context "when on xi service" do
      include_context "with XI service"

      it { is_expected.to render_template(:not_found) }
    end
  end

  describe "GET #show" do
    subject(:do_request) do
      get quota_path(
        id: quota_definition.id,
        order_number: quota_definition.quota_order_number_id,
      )

      response
    end

    before do
      create(:user, :hmrc_editor)

      allow(QuotaOrderNumbers::QuotaDefinition).to receive(:find).with("22619", quota_order_number_id: "051822").and_return(quota_definition)
    end

    let(:quota_definition) do
      build(
        :quota_definition,
        :with_quota_balance_events,
        :with_quota_order_number,
        :with_quota_order_number_origins,
        :without_quota_critical_events,
        :without_quota_unsuspension_events,
        :without_quota_exhaustion_events,
        :without_quota_reopening_events,
        :without_quota_unblocking_events,
      )
    end

    it "fetches the quota definition" do
      do_request

      expect(QuotaOrderNumbers::QuotaDefinition)
        .to have_received(:find)
        .with(quota_definition.id, quota_order_number_id: quota_definition.quota_order_number_id)
    end

    it { is_expected.to render_template(:show) }
  end
end
