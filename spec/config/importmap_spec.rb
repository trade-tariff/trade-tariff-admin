require "rails_helper"
require "json"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Importmap configuration" do
  def importmap_imports
    JSON.parse(
      Rails.application.importmap.to_json(resolver: ApplicationController.helpers),
    ).fetch("imports")
  end

  def split_module_import
    /
      (?:\A|;)
      \s*
      (?:
        import\s*["']\.\/(?:common|components|errors|i18n|init|component) |
        (?:import|export).*?from\s*["']\.\/(?:common|components|errors|i18n|init|component)
      )
    /x
  end

  it "serves GOV.UK Frontend as a single vendored asset" do
    expect(importmap_imports.fetch("govuk-frontend")).to match(%r{\A/assets/govuk-frontend-[0-9a-f]+\.js\z})
  end

  it "vendors GOV.UK Frontend as a self-contained bundle" do
    source = Rails.root.join("vendor/javascript/govuk-frontend.js").read

    expect(source).not_to match(split_module_import)
  end
end
# rubocop:enable RSpec/DescribeClass
