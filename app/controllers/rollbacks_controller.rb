class RollbacksController < AuthenticatedController
  def index
    authorize Rollback, :index?
    @rollbacks = Rollback.all(page: current_page)
  end

  def new
    authorize Rollback, :create?
    @rollback = Rollback.new(rollback_params)
  end

  def create
    authorize Rollback, :create?
    @rollback = Rollback.new(rollback_params)
    @rollback.save

    if @rollback.errors.none?
      redirect_to rollbacks_path, notice: "Rollback was scheduled"
    else
      render :new, status: :unprocessable_content
    end
  end

private

  def rollback_params
    if params[:rollback].blank?
      { date: Time.zone.today, keep: true }
    else
      params
        .require(:rollback)
        .permit(:date, :keep, :reason)
        .to_h
        .merge(user_id: current_user.id)
    end
  end
end
