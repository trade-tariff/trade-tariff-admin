module References
  module Sections
    class SearchReferencesController < References::SearchReferencesController
      private

      def search_reference_parent
        @search_reference_parent ||= Section.find(params[:section_id])
      end
      alias_method :section, :search_reference_parent
      helper_method :section
    end
  end
end
