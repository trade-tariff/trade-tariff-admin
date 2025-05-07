module QuotaOrderNumbers
  class QuotaReopeningEvent
    include ApiEntity

    alias_attribute :event_date, :reopening_date
  end
end
