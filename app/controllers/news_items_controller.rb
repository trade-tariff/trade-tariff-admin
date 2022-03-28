class NewsItemsController < AuthenticatedController
  before_action :authorize_user

  def index
    @news_items = NewsItem.all(page: current_page).fetch
  end

  def new
    @news_item = NewsItem.new
  end

  def create
    @news_item = NewsItem.new(news_item_params)

    if @news_item.valid? && @news_item.save
      redirect_to news_items_path, notice: 'News item created'
    else
      render :new
    end
  end

  def edit
    @news_item = NewsItem.find(params[:id])
  end

  def update
    @news_item = NewsItem.find(params[:id])
    @news_item.attributes = news_item_params

    if @news_item.valid? && @news_item.save
      redirect_to news_items_path, notice: 'News item updated'
    else
      render :edit
    end
  end

  def destroy
    @news_item = NewsItem.find(params[:id])
    @news_item.destroy

    redirect_to news_items_path, notice: 'News item removed'
  end

  private

  def news_item_params
    params.require(:news_item).permit(%i[
      title
      content
      display_style
      show_on_uk
      show_on_xi
      show_on_home_page
      show_on_updates_page
      show_on_banner
      start_date
      end_date
    ]).reverse_merge(default_params)
  end

  def default_params
    { display_style: NewsItem::DISPLAY_STYLE_REGULAR }
  end

  def authorize_user
    authorize NewsItem, :edit?
  end
end
