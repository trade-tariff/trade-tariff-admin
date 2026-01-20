class PagesController < AuthenticatedController
  def index
    # Redirect users to their appropriate start page if this isn't it
    unless default_landing_path == root_path
      skip_authorization
      redirect_to default_landing_path
      return
    end

    authorize SectionNote, :index?

    @sections = Section.all
  end
end
