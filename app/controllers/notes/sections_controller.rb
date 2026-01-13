module Notes
  class SectionsController < AuthenticatedController
    respond_to :json

    def show
      authorize SectionNote, :show?
      respond_with section
    end

    def index
      authorize SectionNote, :index?
      @sections = Section.all
    end

  private

    def section
      @section ||= Section.find(params[:id])
    end
    helper_method :section
  end
end
