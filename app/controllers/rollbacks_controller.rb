class RollbacksController < AuthenticatedController
  before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

  def index
    @rollbacks = Rollback.all(page: current_page)
  end

  def new
    @rollback = Rollback.new
  end

  def create
    @rollback = Rollback.new(rollback_params)
    @rollback.user = current_user
    @rollback.save

    if @rollback.errors.none?
      redirect_to rollbacks_path, notice: 'Rollback was scheduled'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def rollback_params
    params.require(:rollback).permit(:date, :keep, :reason).to_h
  end

  def authorize_user
    authorize Rollback, :access?
  end
end
