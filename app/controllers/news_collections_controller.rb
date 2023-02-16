class NewsCollectionsController < AuthenticatedController
  #before_action :authorize_user TODO

  def index
    @news_collections = News::Collection.all
  end

  def new
    @news_collection = News::Collection.new
  end

  def create
    @news_collection = News::Collection.new(news_collection_params)

    if @news_collection.valid? && @news_collection.save
      redirect_to news_collections_path, notice: 'News collection created'
    else
      render :new
    end
  end

  def edit
    @news_collection = News::Collection.find(params[:id])
  end

  def update
    @news_collection = News::Collection.find(params[:id])
    @news_collection.attributes = news_collection_params

    if @news_collection.valid? && @news_collection.save
      redirect_to news_collections_path, notice: 'News collection updated'
    else
      render :edit
    end
  end

  private

  def news_collection_params
    params.require(:news_collection).permit(%i[
      published
      priority
      description
      name
    ])
  end
end
