module QuotaOrderNumbers
  class QuotaBalanceEvent
    include ApiEntity

    attr_accessor :id,
                  :occurrence_timestamp,
                  :new_balance,
                  :imported_amount,
                  :last_import_date_in_allocation,
                  :old_balance
  end
end
