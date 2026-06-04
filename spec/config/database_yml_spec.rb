# rubocop:disable RSpec/DescribeClass
RSpec.describe "Database configuration" do
  subject(:database_config) do
    YAML.safe_load(
      ERB.new(Rails.root.join("config/database.yml").read).result,
      aliases: true,
    )
  end

  around do |example|
    original_test_env_number = ENV["TEST_ENV_NUMBER"]

    example.run
  ensure
    ENV["TEST_ENV_NUMBER"] = original_test_env_number
  end

  context "when TEST_ENV_NUMBER is not set" do
    before { ENV.delete("TEST_ENV_NUMBER") }

    it "uses the original test database name" do
      expect(database_config.fetch("test").fetch("database")).to eq("tariff_admin_test")
    end
  end

  context "when TEST_ENV_NUMBER is set" do
    before { ENV["TEST_ENV_NUMBER"] = "2" }

    it "uses the matching parallel test database name" do
      expect(database_config.fetch("test").fetch("database")).to eq("tariff_admin_test2")
    end
  end
end
# rubocop:enable RSpec/DescribeClass
