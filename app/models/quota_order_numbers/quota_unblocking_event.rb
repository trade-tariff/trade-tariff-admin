module QuotaOrderNumbers
  class QuotaUnblockingEvent
    include Her::JsonApi::Model

    attributes :id,
               :unblocking_date,
               :event_type

    alias_attribute :event_date, :unblocking_date
  end
end
