module NewsItemsHelper
  def news_item_date(date)
    return unless date

    I18n.l date.to_date, format: :tariff
  end

  def news_item_bool(value)
    value ? 'Yes' : 'No'
  end

  def format_news_item_pages(news_item)
    pages = []

    pages << 'Home' if news_item.show_on_home_page
    pages << 'Updates' if news_item.show_on_updates_page
    pages << 'Banner' if news_item.show_on_banner
    pages << 'No pages' if pages.empty?

    safe_join pages, ', '
  end
end
