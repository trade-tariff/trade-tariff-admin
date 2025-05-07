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
      else
        ''
      end
    end
  end
end
