module QuotaOrderNumbers
  class QuotaUnsuspensionEvent
    include Her::JsonApi::Model

    attributes :id,
               :unsuspension_date,
               :event_type

    alias_attribute :event_date, :unsuspension_date
  end
end
