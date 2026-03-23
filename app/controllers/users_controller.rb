class UsersController < AuthenticatedController
  before_action :set_user, only: %i[edit update destroy]

  def index
    authorize User, :index?
    @users = User.order(:email).page(params[:page] || 1)
  end

  def new
    authorize User, :create?
    @user = User.new(role: User::GUEST)
  end

  def create
    authorize User, :create?

    @user = User.new(create_user_params)
    @user.role = role_param

    if @user.save
      redirect_to users_path, notice: "User added successfully"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @user, :update?
  end

  def update
    authorize @user, :update?

    @user.role = role_param

    if @user.save
      redirect_to users_path, notice: "User role updated successfully"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @user, :destroy?

    @user.destroy!

    redirect_to users_path, notice: "User removed successfully"
  end

private

  def set_user
    @user = User.find(params[:id])
  end

  def create_user_params
    params.require(:user).permit(:email)
  end

  def role_param
    params.require(:user).require(:role)
  end
end
