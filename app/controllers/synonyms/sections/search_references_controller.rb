module Synonyms
  module Sections
    class SearchReferencesController < Synonyms::SearchReferencesController
      private

      def search_reference_parent
        # section_id is a position
        @search_reference_parent ||= Section.find(params[:section_id])
      end
      alias_method :section, :search_reference_parent
      helper_method :section

      def scope
        :synonyms
      end
    end
  end
end
