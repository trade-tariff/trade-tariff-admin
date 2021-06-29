module Synonyms
  module Chapters
    class SearchReferencesController < Synonyms::SearchReferencesController
      private

      def search_reference_parent
        @search_reference_parent ||= Chapter.find(params[:chapter_id])
      end
      alias_method :chapter, :search_reference_parent
      helper_method :chapter

      def scope
        :synonyms
      end
    end
  end
end
