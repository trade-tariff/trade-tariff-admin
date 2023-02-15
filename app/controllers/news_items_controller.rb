class NewsItemsController < AuthenticatedController
  before_action :disable_service_switching!
  before_action :authorize_user

  def index
    @news_items = News::Item.all(page: current_page).fetch
  end

  def new
    @news_item = News::Item.new
    @collections = News::Collection.all.fetch
  end

  def create
    @news_item = News::Item.new(news_item_params)

    if @news_item.valid? && @news_item.save
      redirect_to news_items_path, notice: 'News item created'
    else
      @collections = News::Collection.all.fetch
      render :new
    end
  end

  def edit
    @news_item = News::Item.find(params[:id])
    @collections = News::Collection.all.fetch
  end

  def update
    @news_item = News::Item.find(params[:id])
    @news_item.attributes = news_item_params

    if @news_item.valid? && @news_item.save
      redirect_to news_items_path, notice: 'News item updated'
    else
      @collections = News::Collection.all.fetch
      render :edit
    end
  end

  def destroy
    @news_item = News::Item.find(params[:id])
    @news_item.destroy

    redirect_to news_items_path, notice: 'News item removed'
  end

  private

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
    ], collection_ids: []).reverse_merge(default_params)
  end

  def default_params
    { display_style: News::Item::DISPLAY_STYLE_REGULAR }
  end

  def authorize_user
    authorize News::Item, :edit?
  end
end
