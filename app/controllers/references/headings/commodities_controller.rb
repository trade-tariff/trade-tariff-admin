module References
  module Headings
    class CommoditiesController < AuthenticatedController
      def index
        authorize SearchReference, :index?
        @commodities = heading.commodities
      end

    private

      def heading
        @heading ||= Heading.find(params[:heading_id])
      end
      helper_method :heading
    end
  end
end
