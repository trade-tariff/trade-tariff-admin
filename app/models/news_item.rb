class NewsItem
  include Her::JsonApi::TariffModel
  use_api Her::UK_API

  DISPLAY_STYLE_REGULAR = 0

  collection_path '/admin/news_items'

  attributes :title, :content, :display_style, :show_on_uk, :show_on_xi,
             :show_on_home_page, :show_on_updates_page, :show_on_banner,
             :start_date, :end_date

  validates :title, presence: true
  validates :content, presence: true
  validates :start_date, presence: true

  def preview
    GovspeakPreview.new(content).render
  end
end
