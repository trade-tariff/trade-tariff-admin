class GovspeakPreview
  PLACEHOLDER_PATTERN = /\{\{[a-zA-Z][a-zA-Z0-9_]*\}\}/

  def initialize(content, linkify_code_references: false)
    @content = content.to_s
    @linkify_code_references = linkify_code_references
  end

  def render
    html = govspeak.to_html
    html = GoodsNomenclatureCodeLinkifier.new(html).render if @linkify_code_references
    html = highlight_placeholders(html)

    html.html_safe
  end

private

  def govspeak
    Govspeak::Document.new(substituted_content, sanitize: true)
  end

  def substituted_content
    ServiceHelper.replace_service_tags(@content)
  end

  def highlight_placeholders(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)

    fragment.xpath(".//text() | ./text()").each do |node|
      next unless node.text.match?(PLACEHOLDER_PATTERN)

      node.replace(Nokogiri::HTML::DocumentFragment.parse(highlight_placeholder_text(node.text)))
    end

    fragment.to_html
  end

  def highlight_placeholder_text(text)
    CGI.escapeHTML(text).gsub(PLACEHOLDER_PATTERN) do |placeholder|
      %(<span class="placeholder">#{placeholder}</span>)
    end
  end
end
