class GovspeakPreview
  def initialize(content)
    @content = content.to_s
  end

  def render
    govspeak.to_html.html_safe
  end

  private

  def govspeak
    Govspeak::Document.new(substituted_content, sanitize: true)
  end

  def substituted_content
    ServiceHelper.replace_service_tags(@content)
  end
end
