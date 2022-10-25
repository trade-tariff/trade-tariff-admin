module QuotaOrderNumbers
  class QuotaDefinitionsController < AuthenticatedController
    def current
      @quota_definition = QuotaOrderNumbers::QuotaDefinition.find(params[:id])
    end
  end
end
