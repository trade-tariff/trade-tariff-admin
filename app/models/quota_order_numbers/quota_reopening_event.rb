module QuotaOrderNumbers
  class QuotaReopeningEvent
    include ApiEntity

    attr_accessor :id,
                  :reopening_date,
                  :event_type

    alias_attribute :event_date, :reopening_date
  end
end
