module ServiceHelper
  module_function

  def switch_service_link(*args)
    if TradeTariffAdmin::ServiceChooser.uk?
      link_to('Switch to XI service', "/xi#{current_path}", *args)
    else
      link_to('Switch to UK service', current_path, *args)
    end
  end

  def service_name
    if TradeTariffAdmin::ServiceChooser.uk?
      'UK Integrated Online Tariff'
    else
      'Northern Ireland Online Tariff'
    end
  end

  def service_update_type
    t("helpers.service_update_type.#{TradeTariffAdmin::ServiceChooser.service_name}")
  end

  def service_region
    TradeTariffAdmin::ServiceChooser.uk? ? 'the UK' : 'Northern Ireland'
  end

  def service_path_prefix
    TradeTariffAdmin::ServiceChooser.xi? ? '/xi' : ''
  end

  def locale_path_prefix
    I18n.locale == I18n.default_locale ? '' : "/#{I18n.locale}"
  end

  def replace_service_tags(content)
    content.gsub %r{\[\[[A-Z]+_[A-Z_]+\]\]} do |match|
      case match
      when '[[SERVICE_NAME]]'
        service_name
      when '[[SERVICE_PATH]]'
        service_path_prefix
      when '[[SERVICE_REGION]]'
        service_region
      when '[[LOCALE_PATH]]'
        ''
      when '[[PREFIX_PATH]]'
        service_path_prefix
      else
        match
      end
    end
  end

  private

  def current_path
    request.filtered_path.sub(TradeTariffAdmin::ServiceChooser.service_choice.to_s, '').sub('//', '/')
  end
end
