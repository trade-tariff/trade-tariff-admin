require "rails_helper"

# rubocop:disable RSpec/NestedGroups
RSpec.describe ServiceHelper, type: :helper do
  describe ".service_update_type" do
    subject { service_update_type }

    context "with UK service" do
      include_context "with UK service"

      it { is_expected.to eq("CDS") }
    end

    context "with XI service" do
      include_context "with XI service"

      it { is_expected.to eq("Taric") }
    end
  end

  describe ".service_name" do
    subject { service_name }

    context "with UK service" do
      include_context "with UK service"

      it { is_expected.to eql "UK Integrated Online Tariff" }
    end

    context "with XI service" do
      include_context "with XI service"

      it { is_expected.to eql "Northern Ireland Online Tariff" }
    end
  end

  describe ".service_region" do
    subject { service_region }

    context "with UK service" do
      include_context "with UK service"

      it { is_expected.to eql "the UK" }
    end

    context "with XI service" do
      include_context "with XI service"

      it { is_expected.to eql "Northern Ireland" }
    end
  end

  describe ".switch_service_link" do
    let(:request) { instance_double(ActionDispatch::Request, filtered_path: path) }

    before do
      allow(helper).to receive(:request).and_return(request)
    end

    context "when the selected service choice is nil" do
      include_context "with default service"

      let(:path) { "/rollbacks/new" }

      it "returns the link to the XI service" do
        expect(switch_service_link).to eq(link_to("Switch to XI service", "/xi/rollbacks/new"))
      end
    end

    context "when the selected service choice is uk" do
      include_context "with UK service"

      let(:path) { "/uk/rollbacks/new" }

      it "returns the link to the XI service" do
        expect(switch_service_link).to eq(link_to("Switch to XI service", "/xi/rollbacks/new"))
      end
    end

    context "when the selected service choice is xi" do
      include_context "with XI service"

      let(:path) { "/xi/rollbacks/new" }

      it "returns the link to the current UK service" do
        expect(switch_service_link).to eq(link_to("Switch to UK service", "/rollbacks/new"))
      end

      context "when using the root path" do
        let(:path) { "/xi" }

        it "returns the link to the current UK service" do
          expect(switch_service_link).to eq(link_to("Switch to UK service", "/"))
        end
      end
    end

    context "with a css class" do
      subject { switch_service_link class: "test-class" }

      include_context "with default service"

      let(:path) { "/rollbacks/new" }

      it { is_expected.to have_css "a.test-class" }
    end
  end

  describe ".replace_service_tags" do
    subject { replace_service_tags content }

    context "with UK service" do
      include_context "with UK service"

      context "without tags" do
        let(:content) { "this is some sample content" }

        it { is_expected.to eql "this is some sample content" }
      end

      context "with SERVICE_NAME tag" do
        let(:content) { "You are on the [[SERVICE_NAME]]" }

        it { is_expected.to eql "You are on the UK Integrated Online Tariff" }
      end

      context "with SERVICE_PATH tag" do
        let(:content) { '<a href="[[SERVICE_PATH]]/browse">Browse</a>' }

        it { is_expected.to eql '<a href="/browse">Browse</a>' }
      end

      context "with SERVICE_REGION" do
        let(:content) { "within [[SERVICE_REGION]]" }

        it { is_expected.to eql "within the UK" }
      end

      context "with multiple tags" do
        let :content do
          <<~END_OF_CONTENT
            [[SERVICE_NAME]]
            * [Find commodity]([[SERVICE_PATH]]/find_commodity)
            * [Browse]([[SERVICE_PATH]]/browse)
          END_OF_CONTENT
        end

        let :expected do
          <<~END_OF_EXPECTED
            UK Integrated Online Tariff
            * [Find commodity](/find_commodity)
            * [Browse](/browse)
          END_OF_EXPECTED
        end

        it { is_expected.to eql expected }
      end
    end

    context "with XI service" do
      include_context "with XI service"

      context "without tags" do
        let(:content) { "this is some sample content" }

        it { is_expected.to eql "this is some sample content" }
      end

      context "with SERVICE_NAME tag" do
        let(:content) { "You are on the [[SERVICE_NAME]]" }

        it { is_expected.to eql "You are on the Northern Ireland Online Tariff" }
      end

      context "with SERVICE_PATH tag" do
        let(:content) { '<a href="[[SERVICE_PATH]]/browse">Browse</a>' }

        it { is_expected.to eql '<a href="/xi/browse">Browse</a>' }
      end

      context "with SERVICE_REGION" do
        let(:content) { "within [[SERVICE_REGION]]" }

        it { is_expected.to eql "within Northern Ireland" }
      end

      context "with multiple tags" do
        let :content do
          <<~END_OF_CONTENT
            [[SERVICE_NAME]]
            * [Find commodity]([[SERVICE_PATH]]/find_commodity)
            * [Browse]([[SERVICE_PATH]]/browse)
          END_OF_CONTENT
        end

        let :expected do
          <<~END_OF_EXPECTED
            Northern Ireland Online Tariff
            * [Find commodity](/xi/find_commodity)
            * [Browse](/xi/browse)
          END_OF_EXPECTED
        end

        it { is_expected.to eql expected }
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
