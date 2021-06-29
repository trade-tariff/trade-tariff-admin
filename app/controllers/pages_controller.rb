class PagesController < AuthenticatedController
  def index
    @sections = Section.all
  end
end
