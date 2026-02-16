# rubocop:disable RSpec/NoExpectationExample, RSpec/ExampleLength
RSpec.describe "Entity search in references" do
  let(:section) { build(:section, resource_id: 1, numeral: "I", title: "Live animals; animal products") }
  let(:sections_url) { "#{TradeTariffAdmin::ServiceChooser.api_host}/admin/sections" }
  let(:internal_search_url) { "#{TradeTariffAdmin::ServiceChooser.api_host}/internal/search" }

  let(:chapter) do
    build(
      :chapter,
      :with_section,
      section: section.attributes.merge(resource_id: section.resource_id),
    )
  end

  before do
    stub_request(:get, sections_url)
      .to_return jsonapi_success_response("section", [section.attributes.merge("resource_id" => section.resource_id)])
  end

  describe "partial code search (e.g. 01)" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(
          data: [
            {
              type: "chapter",
              attributes: {
                goods_nomenclature_item_id: "0100000000",
                producline_suffix: "80",
                description: "LIVE ANIMALS",
              },
            },
          ],
        )
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "01"
      click_button "Search"

      expect(page).to have_content("Chapter")
      expect(page).to have_content("01")
      expect(page).to have_content("LIVE ANIMALS")
      expect(page).to have_link("Open")
    end
  end

  describe "four-digit code search (e.g. 0101)" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(
          data: [
            {
              type: "heading",
              attributes: {
                goods_nomenclature_item_id: "0101000000",
                producline_suffix: "80",
                description: "Live horses, asses, mules and hinnies",
              },
            },
          ],
        )
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "0101"
      click_button "Search"

      expect(page).to have_content("Heading")
      expect(page).to have_content("0101")
      expect(page).to have_content("Live horses, asses, mules and hinnies")
      expect(page).to have_link("Open")
    end
  end

  describe "full commodity code search (e.g. 01012100)" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(
          data: [
            {
              type: "commodity",
              attributes: {
                goods_nomenclature_item_id: "0101210000",
                producline_suffix: "80",
                description: "Pure-bred breeding animals",
              },
            },
          ],
        )
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "01012100"
      click_button "Search"

      expect(page).to have_content("Commodity")
      expect(page).to have_content("0101210000-80")
      expect(page).to have_content("Pure-bred breeding animals")
      expect(page).to have_link("Open")
    end
  end

  describe "description search" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(
          data: [
            {
              type: "chapter",
              attributes: {
                goods_nomenclature_item_id: "0100000000",
                description: "Live animals",
              },
            },
          ],
        )
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "live animals"
      click_button "Search"

      expect(page).to have_content("Section")
      expect(page).to have_content("Live animals; animal products")
      expect(page).to have_content("Chapter")
      expect(page).to have_content("Live animals")
    end
  end

  describe "no results found" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(data: [])
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "zzzznotfound"
      click_button "Search"

      expect(page).to have_content("No matching entities found")
      expect(page).to have_content("Try using Browse")
      expect(page).not_to have_css("table")
    end
  end

  describe "clicking Open navigates to entity reference screen" do
    before do
      stub_request(:post, internal_search_url)
        .to_return api_success_response(
          data: [
            {
              type: "heading",
              attributes: {
                goods_nomenclature_item_id: "0101000000",
                description: "Live horses",
              },
            },
          ],
        )

      heading_attrs = chapter.attributes.dup
      heading_attrs["chapter"] = chapter.attributes.merge("resource_id" => chapter.resource_id)
      stub_api_request("/admin/headings/0101")
        .to_return jsonapi_success_response("heading", heading_attrs)

      stub_api_request("/admin/headings/0101/search_references")
        .to_return jsonapi_success_response("search_reference", [])
    end

    specify :aggregate_failures do
      ensure_on references_search_path
      fill_in "Search tariff entities", with: "0101"
      click_button "Search"
      click_link "Open"

      verify current_path == references_heading_search_references_path("0101")
    end
  end

  describe "Browse and Search tabs" do
    specify :aggregate_failures do
      ensure_on references_search_path

      expect(page).to have_link("Browse")
      expect(page).to have_link("Search")
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample, RSpec/ExampleLength
