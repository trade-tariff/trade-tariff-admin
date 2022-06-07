module References
  module Commodities
    class SearchReferencesController < References::SearchReferencesController
      private

      def search_reference_parent
        @search_reference_parent ||= Commodity.find(params[:commodity_id])
      end
      alias_method :commodity, :search_reference_parent
      helper_method :commodity

      def scope
        :references
      end
    end
  end
end
