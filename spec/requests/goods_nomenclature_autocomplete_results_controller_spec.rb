# rubocop:disable RSpec/ExampleLength
RSpec.describe GoodsNomenclatureAutocompleteResultsController, type: :request do
  subject(:rendered_page) { make_request && response }

  include_context "with authenticated user"

  let(:current_user) { create(:user, :technical_operator) }
  let(:make_request) { get goods_nomenclature_autocomplete_results_path(format: :json), params: { q: "1201" } }

  before do
    stub_api_request("/goods_nomenclature_autocomplete")
      .with(query: hash_including("q" => "1201", "filter" => hash_including("goods_nomenclature_class" => %w[Chapter Heading])))
      .and_return(
        status: 200,
        headers: { "content-type" => "application/json; charset=utf-8" },
        body: {
          data: [
            {
              type: "goods_nomenclature_autocomplete",
              id: "120190",
              attributes: {
                "resource_id" => "120190",
                "goods_nomenclature_item_id" => "1201900000",
                "description" => "Soya bean flour and meal, whether or not defatted",
              },
            },
          ],
        }.to_json,
      )
  end

  it { is_expected.to have_http_status :success }

  it "returns autocomplete suggestions" do
    json = JSON.parse(rendered_page.body)

    expect(json).to eq([
      {
        "id" => "120190",
        "goods_nomenclature_item_id" => "1201900000",
        "description" => "Soya bean flour and meal, whether or not defatted",
        "truncated_description" => "Soya bean flour and meal, whether or not defatted",
        "label" => "1201900000 - Soya bean flour and meal, whether or not defatted",
      },
    ])
  end
end

# rubocop:enable RSpec/ExampleLength
