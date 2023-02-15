class NewsCollectionsController < AuthenticatedController
  #before_action :authorize_user TODO

  def index
    @news_collections = News::Collection.all
  end
end
