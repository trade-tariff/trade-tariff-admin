module QuotaOrderNumbers
  class QuotaExhaustionEvent
    include ApiEntity

    alias_attribute :event_date, :exhaustion_date
  end
end
