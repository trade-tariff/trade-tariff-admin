module QuotaOrderNumbers
  class QuotaUnblockingEvent
    include ApiEntity

    alias_attribute :event_date, :unblocking_date
  end
end
