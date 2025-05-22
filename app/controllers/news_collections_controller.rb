class NewsCollectionsController < AuthenticatedController
  before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

  def index
    @news_collections = News::Collection.all.sort_by(&:id)
  end

  def new
    @news_collection = News::Collection.new
  end

  def create
    @news_collection = News::Collection.new(news_collection_params)
    @news_collection.generate_or_normalise_slug!
    @news_collection.save

    if @news_collection.errors.none?
      redirect_to news_collections_path, notice: 'News collection created'
    else
      render :new
    end
  end

  def edit
    @news_collection = News::Collection.find(params[:id])
  end

  def update
    @news_collection = News::Collection.build(news_collection_params.merge(resource_id: params[:id]))
    @news_collection.generate_or_normalise_slug!
    @news_collection.save

    if @news_collection.errors.none?
      redirect_to news_collections_path, notice: 'News collection updated'
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

  def authorize_user
    authorize News::Collection, :edit?
  end
end
