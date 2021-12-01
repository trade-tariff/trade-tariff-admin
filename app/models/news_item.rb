class NewsItem
  include Her::JsonApi::Model
  use_api Her::UK_API

  DISPLAY_STYLE_REGULAR = 0

  collection_path '/admin/news_items'

  attributes :title, :content, :display_style, :show_on_uk, :show_on_xi,
             :show_on_home_page, :show_on_updates_page, :start_date, :end_date

  validates :title, presence: true
  validates :content, presence: true
  validates :start_date, presence: true

  def preview
    substituted_content = ApplicationController.helpers.replace_service_tags(content.to_s)

    Govspeak::Document.new(substituted_content, sanitize: true).to_html.html_safe
  end
end
