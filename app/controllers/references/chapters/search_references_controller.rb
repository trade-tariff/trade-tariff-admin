module References
  module Chapters
    class SearchReferencesController < References::SearchReferencesController
      private

      def search_reference_parent
        @search_reference_parent ||= Chapter.find(params[:chapter_id])
      end
      alias_method :chapter, :search_reference_parent
      helper_method :chapter

      def scope
        :references
      end
    end
  end
end
