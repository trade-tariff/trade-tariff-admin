class RollbacksController < AuthenticatedController
  include MultipartDate

  def index
    authorize Rollback, :index?
    @rollbacks = Rollback.all(page: current_page)
  end

  def new
    authorize Rollback, :create?
    @rollback = Rollback.new
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
    permitted = params.require(:rollback).permit(
      %i[keep reason],
      **multipart_date_params(%w[date]),
    )

    compose_date_params(
      permitted_params: permitted,
      hash: :rollback,
      date_params: %i[date],
    )
  end
end
