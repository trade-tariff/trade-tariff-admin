module ServiceHelper
  def switch_service_link(*args)
    if TradeTariffAdmin::ServiceChooser.uk?
      link_to('Switch to XI service', "/xi#{current_path}", *args)
    else
      link_to('Switch to UK service', current_path, *args)
    end
  end

  private

  def current_path
    request.filtered_path.sub(TradeTariffAdmin::ServiceChooser.service_choice.to_s, '').sub('//', '/')
  end
end
