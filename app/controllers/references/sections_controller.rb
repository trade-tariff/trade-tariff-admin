module References
  class SectionsController < AuthenticatedController
    respond_to :json

    def show
      authorize SearchReference, :show?
      respond_with section
    end

    def index
      authorize SearchReference, :index?
      @sections = Section.all
    end

  private

    def section
      @section ||= Section.find(params[:id])
    end
    helper_method :section
  end
end
