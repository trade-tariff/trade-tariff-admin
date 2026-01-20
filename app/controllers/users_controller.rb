class UsersController < AuthenticatedController
  before_action :set_user, only: %i[edit update]

  def index
    authorize User, :index?
    @users = User.order(:email).page(params[:page] || 1)
  end

  def edit
    authorize @user, :update?
    # Ensure the role attribute is set for the form
    @user.role = @user.current_role
  end

  def update
    authorize @user, :update?
    @user.role = user_params[:role]

    # Check if role assignment added any errors
    if @user.errors[:role].any? || !@user.save
      render :edit, status: :unprocessable_content
    else
      redirect_to users_path, notice: "User role updated successfully"
    end
  end

private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role)
  end
end
