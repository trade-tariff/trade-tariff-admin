module GreenLanes
  class UpdateNotification
    include ApiEntity

    xi_only

    def status_label
      case status
      when 0
        'Created'
      when 1
        'Updated'
      when 2
        'Expired'
      when 3
        'Category Assessment Created'
      else
        ''
      end
    end
  end
end
