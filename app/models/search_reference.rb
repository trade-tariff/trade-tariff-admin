class SearchReference
  include ApiEntity

  SEARCH_USAGE = "search".freeze
  FPO_USAGE = "fpo".freeze
  USAGE_NAMES = {
    SEARCH_USAGE => "Search",
    FPO_USAGE => "FPO only",
  }.freeze
  ALL_USAGES = "all".freeze
  USAGE_FILTERS = USAGE_NAMES.merge(ALL_USAGES => "All").freeze

  # Virtual attributes used by the Admin UI only (not part of the API payload).
  attr_accessor :release_services, :release_to_uk, :release_to_xi

  attributes :title,
             :referenced_id,
             :referenced_class,
             :usage

  def self.collection_options(casted_by:, usage: nil)
    options = { casted_by: }
    options[:filter] = { usage: } if USAGE_FILTERS.key?(usage)
    options
  end

  def fpo?
    usage == FPO_USAGE
  end

  def usage_name
    USAGE_NAMES.fetch(usage.presence || SEARCH_USAGE, usage)
  end

  def normalize_serialized_attributes(attrs)
    %w[release_services release_to_uk release_to_xi].each do |key|
      attrs.delete(key)
      attrs.delete(key.to_sym)
    end
  end
end
