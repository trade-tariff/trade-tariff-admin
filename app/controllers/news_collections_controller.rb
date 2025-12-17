class NewsCollectionsController < AuthenticatedController
  def index
    authorize News::Collection, :index?
    @news_collections = News::Collection.all.sort_by(&:id)
  end

  def new
    authorize News::Collection, :create?
    @news_collection = News::Collection.new
  end

  def create
    authorize News::Collection, :create?
    @news_collection = News::Collection.new(news_collection_params)
    @news_collection.generate_or_normalise_slug!
    @news_collection.save

    if @news_collection.errors.none?
      redirect_to news_collections_path, notice: "News collection created"
    else
      render :new
    end
  end

  def edit
    @news_collection = News::Collection.find(params[:id])
    authorize @news_collection, :update?
  end

  def update
    @news_collection = News::Collection.build(news_collection_params.merge(resource_id: params[:id]))
    authorize @news_collection, :update?
    @news_collection.generate_or_normalise_slug!
    @news_collection.save

    if @news_collection.errors.none?
      redirect_to news_collections_path, notice: "News collection updated"
    else
      render :edit
    end
  end

private

  def news_collection_params
    params.require(:news_collection).permit(%i[
      subscribable
      published
      priority
      description
      name
    ])
  end
end
