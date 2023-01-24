module QuotaOrderNumbers
  class QuotaCriticalEvent
    include Her::JsonApi::Model

    attributes :id,
               :critical_state_change_date,
               :event_type,
               :critical_state

    alias_attribute :event_date, :critical_state_change_date
  end
end
