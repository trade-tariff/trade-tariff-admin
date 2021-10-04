class NewsItem
  include Her::JsonApi::Model

  DISPLAY_STYLE_REGULAR = 0

  collection_path '/admin/news_items'

  def assign_errors
    response_errors.each do |attribute|
      attribute[:detail].each do |error_message|
        errors.add(attribute[:title], error_message)
      end
    end
  end
end
