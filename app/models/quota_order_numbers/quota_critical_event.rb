module QuotaOrderNumbers
  class QuotaCriticalEvent
    include ApiEntity

    alias_attribute :event_date, :critical_state_change_date
  end
end
