module QuotaOrderNumbers
  class QuotaExhaustionEvent
    include Her::JsonApi::Model

    attributes :id,
               :exhaustion_date,
               :event_type

    alias_attribute :event_date, :exhaustion_date
  end
end
