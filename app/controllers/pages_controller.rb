class PagesController < AuthenticatedController
  def index
    skip_authorization
    redirect_to default_landing_path
  end
end
