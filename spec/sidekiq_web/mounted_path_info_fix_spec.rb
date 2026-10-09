require "rails_helper"

RSpec.describe MountedPathInfoFix do
  subject(:wrapper) { described_class.new(app) }

  let(:seen_env) { {} }
  let(:app) do
    lambda do |env|
      seen_env["SCRIPT_NAME"] = env["SCRIPT_NAME"]
      seen_env["PATH_INFO"] = env["PATH_INFO"]
      [200, {}, %w[ok]]
    end
  end

  it "removes the script name from a nested path" do
    wrapper.call("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/sidekiq/uk/queues")

    expect(seen_env).to eq("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/queues")
  end

  it "changes a path equal to the script name to the root path" do
    wrapper.call("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/sidekiq/uk")

    expect(seen_env["PATH_INFO"]).to eq("/")
  end

  it "does not change a path that Rails already made relative" do
    wrapper.call("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/queues")

    expect(seen_env["PATH_INFO"]).to eq("/queues")
  end

  it "does not remove a prefix that is only part of a path segment" do
    wrapper.call("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/sidekiq/ukraine")

    expect(seen_env["PATH_INFO"]).to eq("/sidekiq/ukraine")
  end

  it "does not change the path when there is no script name" do
    wrapper.call("SCRIPT_NAME" => "", "PATH_INFO" => "/queues")

    expect(seen_env["PATH_INFO"]).to eq("/queues")
  end

  it "returns the response of the wrapped app" do
    response = wrapper.call("SCRIPT_NAME" => "/sidekiq/uk", "PATH_INFO" => "/sidekiq/uk")

    expect(response).to eq([200, {}, %w[ok]])
  end
end
