module NewsItemsHelper
  def news_item_date(date)
    return unless date

    I18n.l date.to_date, format: :tariff
  end

  def news_item_bool(value)
    value ? 'Yes' : 'No'
  end
end
