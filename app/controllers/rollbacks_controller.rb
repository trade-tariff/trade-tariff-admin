class RollbacksController < AuthenticatedController
  before_action :authorize_user

  def index
    @rollbacks = Rollback.all(page: current_page).fetch
  end

  def new
    @rollback = Rollback.new
    @rollback.attributes = rollback_params if params[:rollback].present?
  end

  def create
    @rollback = Rollback.new(rollback_params)
    @rollback.user = current_user

    if @rollback.valid? && @rollback.save
      redirect_to rollbacks_path, notice: 'Rollback was scheduled'
    else
      @rollback.initialize_errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def rollback_params
    params.require(:rollback).permit(:date, :keep, :reason, :confirm_service).to_h
  end

  def authorize_user
    authorize Rollback, :access?
  end
end
