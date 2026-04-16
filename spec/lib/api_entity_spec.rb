RSpec.describe ApiEntity do
  subject(:pagination) { api_entity_class.send(:pagination_for, records) }

  let(:api_entity_class) do
    Class.new do
      include ApiEntity
      boolean_attributes :published
    end
  end

  before do
    stub_const("ApiEntityPaginationExample", api_entity_class)
  end

  describe ".pagination_for" do
    let(:records) { Kaminari.paginate_array(%w[a b], total_count: 42).page(3).per(2) }

    it "returns pagination metadata from API collections" do
      expect(pagination).to eq(page: 3, per_page: 2, total_count: 42, total_pages: 21)
    end

    context "with plain arrays" do
      let(:records) { %w[a b] }

      it "returns a safe default shape" do
        expect(pagination).to eq(page: 1, per_page: 20, total_count: 2, total_pages: 1)
      end
    end
  end

  describe ".boolean_attributes" do
    it "defines predicate methods for boolean API attributes" do
      expect(api_entity_class.new(published: true).published?).to be(true)
    end

    it "defaults missing boolean API attributes to false" do
      expect(api_entity_class.new.published?).to be(false)
    end
  end
end
