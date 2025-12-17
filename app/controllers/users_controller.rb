class UsersController < AuthenticatedController
  before_action :authorize_user, if: -> { TradeTariffAdmin.authorization_enabled? && !TradeTariffAdmin.basic_session_authentication? }
  before_action :set_user, only: %i[edit update]

  def index
    @users = User.order(:email).page(params[:page] || 1)
  end

  def edit
    # Ensure the role attribute is set for the form
    @user.role = @user.current_role
  end

  def update
    @user.role = user_params[:role]
    
    if @user.save
      redirect_to users_path, notice: "User role updated successfully"
    else
      render :edit, status: :unprocessable_content
    end
  end

private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role)
  end

  def authorize_user
    authorize @user || User, :edit?
  end
end

