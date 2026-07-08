require "rails_helper"
require "json"
require "open3"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Importmap configuration" do
  def importmap_imports(env = {})
    stdout, status = Open3.capture2(
      env,
      "bin/rails",
      "runner",
      "puts Rails.application.importmap.to_json(resolver: ApplicationController.helpers)",
    )
    raise stdout unless status.success?

    JSON.parse(stdout).fetch("imports")
  end

  it "pins GOV.UK Frontend to the bundled ES module" do
    expect(importmap_imports.fetch("govuk-frontend")).to include("/assets/govuk-frontend/dist/govuk/all.bundle")
  end

  it "uses the configured asset host for importmap asset URLs" do
    imports = importmap_imports("ASSET_HOST" => "http://localhost:3003")

    expect(imports.fetch("govuk-frontend")).to start_with("http://localhost:3003/assets/")
  end

  it "vendors Chart.js as a self-contained browser module" do
    chart_js = Rails.root.join("vendor/javascript/chart.js.js").read

    expect(chart_js).not_to match(/(?:from|import)\s*["'](?:\.{1,2}\/|\/)/)
  end
end
# rubocop:enable RSpec/DescribeClass
