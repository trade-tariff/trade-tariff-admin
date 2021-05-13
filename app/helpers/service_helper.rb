module ServiceHelper
  def switch_service_link
    return link_to('Switch to XI service', "/xi#{current_path}") if TradeTariffAdmin::ServiceChooser.uk?

    link_to('Switch to UK service', current_path)
  end

  private

  def current_path
    request.filtered_path.sub("/#{TradeTariffAdmin::ServiceChooser.service_choice}", '')
  end
end
