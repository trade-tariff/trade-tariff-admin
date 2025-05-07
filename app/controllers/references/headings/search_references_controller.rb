module References
  module Headings
    class SearchReferencesController < References::SearchReferencesController
      private

      def search_reference_parent
        @search_reference_parent ||= Heading.find(params[:heading_id])
      end
      alias_method :heading, :search_reference_parent
      helper_method :heading
    end
  end
end
