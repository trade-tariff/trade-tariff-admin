module QuotaOrderNumbers
  class QuotaUnblockingEvent
    include ApiEntity

    attr_accessor :id,
                  :unblocking_date,
                  :event_type

    alias_attribute :event_date, :unblocking_date
  end
end
