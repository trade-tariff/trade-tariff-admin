class NewsItemsController < AuthenticatedController
  before_action :disable_service_switching!

  def index
    authorize News::Item, :index?
    @news_items = News::Item.all(page: current_page)
  end

  def new
    authorize News::Item, :create?
    @news_item = News::Item.new(notify_subscribers: true)
    @collections = collection_options
  end

  def create
    authorize News::Item, :create?
    @news_item = News::Item.new(news_item_params)
    @news_item.generate_or_normalise_slug!
    @news_item.save

    if @news_item.errors.none?
      redirect_to news_items_path, notice: "News item created"
    else
      @collections = collection_options
      render :new
    end
  end

  def edit
    @news_item = News::Item.find(params[:id])
    authorize @news_item, :update?
    @collections = collection_options
  end

  def update
    @news_item = News::Item.build(news_item_params.merge(resource_id: params[:id]))
    authorize @news_item, :update?
    @news_item.generate_or_normalise_slug!
    @news_item.save

    if @news_item.errors.none?
      redirect_to news_items_path, notice: "News item updated"
    else
      @collections = collection_options
      render :edit
    end
  end

  def destroy
    @news_item = News::Item.find(params[:id])
    authorize @news_item, :destroy?
    @news_item.destroy

    redirect_to news_items_path, notice: "News item removed"
  end

private

  def collection_options
    News::Collection.all.map do |collection|
      collection.resource_id = collection&.resource_id.to_i
      collection
    end
  end

  def news_item_params
    params.require(:news_item).permit(%i[
      title
      slug
      content
      precis
      display_style
      show_on_uk
      show_on_xi
      show_on_home_page
      show_on_updates_page
      show_on_banner
      start_date
      end_date
      chapters
      notify_subscribers
    ], collection_ids: []).reverse_merge(default_params)
  end

  def default_params
    { display_style: News::Item::DISPLAY_STYLE_REGULAR }
  end
end
