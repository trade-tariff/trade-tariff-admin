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

    def presented_measure_type_id
      if try(:measure_type_description).present?
        "<abbr title='#{measure_type_description}'>#{measure_type_id}</abbr>"
      else
        measure_type_id
      end
    end

    def presented_regulation_id
      if try(:regulation_description)
        "<abbr title='#{regulation_description}'>#{regulation_id}</abbr>"
      else
        regulation_id
      end
    end
  end
end
