require "rails_helper"

RSpec.describe TradeTariffAdmin::ServiceChooser do
  after do
    Thread.current[:service_choice] = nil
  end

  describe ".service_choices" do
    it "returns a Hash of url options for the services" do
      expect(described_class.service_choices).to eq(
        "uk" => "http://localhost:3018",
        "xi" => "http://localhost:3019",
      )
    end
  end

  describe ".service_choice=" do
    it "assigns the service choice to the current Thread" do
      expect { described_class.service_choice = "xi" }
        .to change { Thread.current[:service_choice] }
        .from(nil)
        .to("xi")
    end
  end

  describe ".api_host" do
    before do
      Thread.current[:service_choice] = choice
    end

    context "when the service choice does not have a corresponding url" do
      let(:choice) { "foo" }

      it "returns the default service choice url" do
        expect(described_class.api_host).to eq("http://localhost:3018")
      end
    end

    context "when the service choice has a corresponding url" do
      let(:choice) { "xi" }

      it "returns the service choice url" do
        expect(described_class.api_host).to eq("http://localhost:3019")
      end
    end
  end

  describe ".uk?" do
    before do
      Thread.current[:service_choice] = choice
    end

    context "when the service choice is not set" do
      let(:choice) { nil }

      it { expect(described_class).to be_uk }
    end

    context "when the service choice is uk" do
      let(:choice) { "uk" }

      it { expect(described_class).to be_uk }
    end

    context "when the service choice is xi" do
      let(:choice) { "xi" }

      it { expect(described_class).not_to be_uk }
    end
  end

  describe ".xi?" do
    before do
      Thread.current[:service_choice] = choice
    end

    context "when the service choice is not set" do
      let(:choice) { nil }

      it { expect(described_class).not_to be_xi }
    end

    context "when the service choice is xi" do
      let(:choice) { "xi" }

      it { expect(described_class).to be_xi }
    end

    context "when the service choice is uk" do
      let(:choice) { "uk" }

      it { expect(described_class).not_to be_xi }
    end
  end
end
