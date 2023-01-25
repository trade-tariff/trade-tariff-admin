module QuotaOrderNumbers
  class QuotaDefinition
    include Her::JsonApi::Model

    resource_path '/admin/quota_order_numbers/:quota_order_number_id/quota_definitions/:id'
    collection_path '/admin/quota_order_numbers/:quota_order_number_id/quota_definitions'

    scope :by_quota_order_number, ->(order_number) { all(_quota_order_number_id: order_number) }

    attributes :id,
               :quota_order_number_id,
               :validity_start_date,
               :validity_end_date,
               :initial_volume,
               :measurement_unit,
               :quota_type,
               :critical_state,
               :critical_threshold

    has_one :quota_order_number
    has_many :quota_balance_events
    has_many :quota_order_number_origins
    has_many :quota_unsuspension_events
    has_many :quota_exhaustion_events
    has_many :quota_reopening_events
    has_many :quota_unblocking_events
    has_many :quota_critical_events

    def occurrence_timestamps
      chart_data[:occurrence_timestamps]
    end

    def imported_amounts
      chart_data[:imported_amounts]
    end

    def new_balances
      chart_data[:new_balances]
    end

    def additional_events
      quota_exhaustion_events + quota_unsuspension_events + quota_reopening_events + quota_unblocking_events + quota_critical_events
    end

    private

    def chart_data
      @chart_data ||= quota_balance_events.each_with_object(occurrence_timestamps: [], imported_amounts: [], new_balances: []) do |event, acc|
        acc[:occurrence_timestamps] << event.occurrence_timestamp.to_date.to_formatted_s(:govuk_short)
        acc[:imported_amounts] << event.imported_amount
        acc[:new_balances] << event.new_balance
      end
    end
  end
end
