class BalanceEventsController < AuthenticatedController
  def show
    quota_definitions ||= QuotaOrderNumbers::QuotaDefinition.by_quota_order_number(params[:id])
    
    @current_quota_definition ||= quota_definitions.max_by(&:validity_end_date)
  end
end
