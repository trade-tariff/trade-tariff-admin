module QuotaOrderNumbers
  class QuotaUnsuspensionEvent
    include ApiEntity

    alias_attribute :event_date, :unsuspension_date
  end
end
