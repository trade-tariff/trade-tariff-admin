module Notes
  class ChaptersController < AuthenticatedController
    respond_to :json

    def index
      authorize ChapterNote, :index?
    end

    def show
      authorize ChapterNote, :show?
      respond_with chapter
    end

  private

    def chapter
      @chapter ||= Chapter.find(params[:id])
    end
    helper_method :chapter
  end
end
