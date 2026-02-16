module References
  class EntitySearch
    Result = Data.define(:entity_type, :code, :description, :path)

    class << self
      def call(query:)
        new(query:).call
      end
    end

    def initialize(query:)
      @query = query.to_s.strip
    end

    def call
      return [] if query.blank?

      (section_results + internal_results).uniq { |result| [result.entity_type, result.code] }
    end

  private

    attr_reader :query

    def section_results
      Section.all.filter_map do |section|
        next unless matches_section?(section)

        Result.new(
          entity_type: "Section",
          code: section.numeral.to_s,
          description: section.title.to_s,
          path: routes.references_section_chapters_path(section),
        )
      end
    rescue Faraday::Error => e
      Rails.logger.warn("references section search failed: #{e.class} #{e.message}")
      []
    end

    def matches_section?(section)
      term = query.downcase
      [
        section.position,
        section.numeral,
        section.title,
      ].compact.any? { |value| value.to_s.downcase.include?(term) }
    end

    def internal_results
      response = TradeTariffAdmin::ServiceChooser.api_client.post("internal/search", q: query)
      data = parse_response_body(response).fetch("data", [])

      data.filter_map do |entry|
        attributes = entry["attributes"] || {}
        code = attributes["goods_nomenclature_item_id"].to_s
        description = attributes["description"].to_s

        next if code.blank? || description.blank?

        build_result(type: entry["type"], code:, description:, attributes:)
      end
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.warn("references entity search failed: #{e.class} #{e.message}")
      []
    end

    def parse_response_body(response)
      body = response.respond_to?(:body) ? response.body : response[:body]
      return {} if body.blank?
      return JSON.parse(body) if body.is_a?(String)

      body
    end

    def build_result(type:, code:, description:, attributes:)
      case type.to_s
      when "chapter"
        build_chapter_result(code:, description:)
      when "heading", "subheading"
        build_heading_result(code:, description:)
      when "commodity"
        build_commodity_result(code:, description:, attributes:)
      end
    end

    def build_chapter_result(code:, description:)
      chapter_code = code.first(2)
      return if chapter_code.blank?

      Result.new(
        entity_type: "Chapter",
        code: chapter_code,
        description:,
        path: routes.references_chapter_search_references_path(chapter_code),
      )
    end

    def build_heading_result(code:, description:)
      heading_code = code.first(4)
      return if heading_code.blank?

      Result.new(
        entity_type: "Heading",
        code: heading_code,
        description:,
        path: routes.references_heading_search_references_path(heading_code),
      )
    end

    def build_commodity_result(code:, description:, attributes:)
      suffix = attributes["producline_suffix"].to_s
      return if suffix.blank?

      Result.new(
        entity_type: "Commodity",
        code: "#{code}-#{suffix}",
        description:,
        path: routes.references_commodity_search_references_path("#{code}-#{suffix}"),
      )
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
