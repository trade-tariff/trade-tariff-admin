class NewsItem
  include Her::JsonApi::Model

  DISPLAY_STYLE_REGULAR = 0

  collection_path '/admin/news_items'


end
