module QuotaOrderNumbers
  class QuotaExhaustionEvent
    include ApiEntity

    attr_accessor :id,
                  :exhaustion_date,
                  :event_type

    alias_attribute :event_date, :exhaustion_date
  end
end
