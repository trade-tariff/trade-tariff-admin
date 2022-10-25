module QuotaOrderNumbers
  class QuotaBalanceEvent
    include Her::JsonApi::Model

    attributes :id,
               :occurrence_timestamp,
               :new_balance,
               :imported_amount
  end
end
