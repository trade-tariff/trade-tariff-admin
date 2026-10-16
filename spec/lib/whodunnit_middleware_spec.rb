require "whodunnit_middleware"

RSpec.describe WhodunnitMiddleware do
  subject(:headers) do
    env = Faraday::Env.from(request_headers: Faraday::Utils::Headers.new)
    described_class.new(->(_env) {}).on_request(env)
    env.request_headers
  end

  after { Current.reset }

  context "when the user ID and name are set" do
    before do
      Current.whodunnit = "user-123"
      Current.whodunnit_name = "Jane Smith"
    end

    it { is_expected.to include("X-Whodunnit" => "user-123", "X-Whodunnit-Name" => "Jane%20Smith") }
  end

  context "when the name has non-ASCII characters" do
    before do
      Current.whodunnit = "user-123"
      Current.whodunnit_name = "Zoë"
    end

    it { is_expected.to include("X-Whodunnit-Name" => "Zo%C3%AB") }
  end

  context "when the name is blank" do
    before do
      Current.whodunnit = "user-123"
      Current.whodunnit_name = ""
    end

    it { is_expected.to include("X-Whodunnit" => "user-123") }
    it { is_expected.not_to have_key("X-Whodunnit-Name") }
  end

  context "when nothing is set" do
    it { is_expected.not_to have_key("X-Whodunnit") }
    it { is_expected.not_to have_key("X-Whodunnit-Name") }
  end
end
