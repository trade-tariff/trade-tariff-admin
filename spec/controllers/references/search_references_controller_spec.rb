RSpec.describe References::SearchReferencesController do
  let(:controller) { described_class.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_references) { double }
  let(:parent) { double(id: "parent-1", search_references:) }
  let(:failed_reference) { SearchReference.new }

  def reference
    @reference ||= SearchReference.new(title: "Matching title")
  end

  before do
    allow(controller).to receive_messages(
      authorize: nil,
      params:,
      redirect_to: nil,
      render: nil,
      search_reference_parent: parent,
    )
  end

  describe "form actions" do
    it "applies selected services to a new reference" do
      params.merge!(release_to_uk: "1", release_to_xi: "0")

      controller.new

      expect(controller.instance_variable_get(:@search_reference).release_to_uk).to eq(1)
    end

    context "when create fails" do
      before do
        params.merge!(search_reference: { title: "reference", release_to_uk: "1", release_to_xi: "0" })
        failed_reference.errors.add(:title, "is invalid")
        allow(failed_reference).to receive(:save)
        allow(controller).to receive(:build_search_reference).and_return(failed_reference)
      end

      it "renders the failed reference" do
        controller.create

        expect(controller).to have_received(:render).with(:new, status: :unprocessable_content)
      end
    end

    it "applies selected services when editing" do
      params.merge!(release_to_uk: "0", release_to_xi: "1")
      reference = SearchReference.new
      allow(controller).to receive(:search_reference_for_action).and_return(reference)

      controller.edit

      expect(reference.release_to_xi).to eq(1)
    end

    it "defaults both services on the removal form" do
      allow(controller).to receive(:search_reference_for_action).and_return(nil)

      controller.remove

      expect(controller.instance_variable_get(:@search_reference).release_to_xi).to eq(1)
    end
  end

  describe "validation failures" do
    before do
      params.merge!(search_reference: {
        title: "reference",
        original_title: "original",
        release_to_uk: "0",
        release_to_xi: "0",
      })
      allow(controller).to receive(:search_reference_for_action).and_return(nil)
    end

    it "renders edit when no update service is selected" do
      controller.update

      expect(controller).to have_received(:render).with(:edit, status: :unprocessable_contents)
    end

    it "renders remove when no destroy service is selected" do
      controller.destroy

      expect(controller).to have_received(:render).with(:remove, status: :unprocessable_content)
    end

    context "when persistence fails" do
      before do
        params[:search_reference][:release_to_uk] = "1"
        allow(controller).to receive(:run_for_selected_services).and_return([failed_reference, [], []])
      end

      it "renders a reference that fails to update" do
        controller.update

        expect(controller).to have_received(:render).with(:edit, status: :unprocessable_content)
      end

      it "redirects after a reference fails to be destroyed" do
        controller.destroy

        expect(controller).to have_received(:redirect_to).with(
          [:references, parent, :search_references],
          alert: "Search reference could not be removed.",
        )
      end
    end
  end

  describe "fallback lookup" do
    before do
      params.merge!(id: "missing", original_title: " matching title ")
      allow(search_references).to receive(:find).and_raise(Faraday::ResourceNotFound, "missing")
    end

    it "falls back by title after a GET lookup misses" do
      collection = [reference]
      allow(collection).to receive(:find).and_raise(Faraday::ResourceNotFound, "missing")
      allow(parent).to receive(:search_references).and_return(collection)
      allow(controller).to receive(:request).and_return(double(get?: true))

      expect(controller.send(:search_reference_for_action)).to eq(reference)
    end

    it "returns nil for a blank original title" do
      params[:original_title] = " "

      expect(controller.send(:normalised_original_title_param)).to be_nil
    end

    it "tries other services when the current service has no match" do
      allow(parent).to receive(:search_references).and_return([], [reference])

      expect(controller.send(:fallback_reference_by_original_title)).to eq(reference)
    end

    it "handles a missing current-service collection" do
      allow(search_references).to receive(:detect).and_raise(Faraday::ResourceNotFound, "missing")

      expect(controller.send(:fallback_reference_by_original_title)).to be_nil
    end

    it "handles a missing collection in another service" do
      TradeTariffAdmin::ServiceChooser.service_choice = "uk"
      allow(search_references).to receive(:detect).and_raise(Faraday::ResourceNotFound, "missing")

      expect(controller.send(:fallback_reference_from_other_services)).to be_nil
    end
  end

  describe "private helpers" do
    it "stops service iteration when a reference has errors" do
      failed_reference = SearchReference.new
      failed_reference.errors.add(:title, "is invalid")

      result = controller.send(:run_for_selected_services, %w[uk xi]) { failed_reference }

      expect(result).to eq([failed_reference, [], []])
    end

    it "requires subclasses to provide a parent" do
      allow(controller).to receive(:search_reference_parent).and_call_original

      expect { controller.send(:search_reference_parent) }
        .to raise_error(NotImplementedError, "Please override #search_reference_parent")
    end
  end
end
