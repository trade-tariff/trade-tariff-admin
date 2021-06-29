module Synonyms
  module Chapters
    class HeadingsController < AuthenticatedController
      def index
        @headings = chapter.headings
      end

      private

      def chapter
        @chapter ||= Chapter.find(params[:chapter_id])
      end
      helper_method :chapter
    end
  end
end
