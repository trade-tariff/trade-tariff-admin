class PagesController < AuthenticatedController
  def index
    authorize SectionNote, :index?
    @sections = Section.all
  end
end
