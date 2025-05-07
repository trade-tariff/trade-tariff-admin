module QuotaOrderNumbers
  class QuotaUnsuspensionEvent
    include ApiEntity

    attr_accessor :id,
                  :unsuspension_date,
                  :event_type

    alias_attribute :event_date, :unsuspension_date
  end
end
