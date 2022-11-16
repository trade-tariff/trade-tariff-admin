class NewsItem
  include Her::JsonApi::Model
  use_api Her::UK_API

  DISPLAY_STYLE_REGULAR = 0

  collection_path '/admin/news_items'

  attributes :title, :content, :display_style, :show_on_uk, :show_on_xi,
             :show_on_home_page, :show_on_updates_page, :show_on_banner,
             :start_date, :end_date

  def preview
    GovspeakPreview.new(content).render
  end
end
