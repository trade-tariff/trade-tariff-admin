module QuotaOrderNumbers
  class QuotaReopeningEvent
    include Her::JsonApi::Model

    attributes :id,
               :reopening_date,
               :event_type

    alias_attribute :event_date, :reopening_date
  end
end
