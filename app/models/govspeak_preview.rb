class GovspeakPreview
  def initialize(content, linkify_code_references: false)
    @content = content.to_s
    @linkify_code_references = linkify_code_references
  end

  def render
    html = govspeak.to_html
    html = GoodsNomenclatureCodeLinkifier.new(html).render if @linkify_code_references

    html.html_safe
  end

private

  def govspeak
    Govspeak::Document.new(substituted_content, sanitize: true)
  end

  def substituted_content
    ServiceHelper.replace_service_tags(@content)
  end
end
