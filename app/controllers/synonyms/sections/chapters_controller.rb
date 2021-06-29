module Synonyms
  module Sections
    class ChaptersController < AuthenticatedController
      def index
        @chapters = section.chapters
      end

      private

      def section
        # section_id is a position
        @section ||= Section.find(params[:section_id])
      end
      helper_method :section
    end
  end
end
