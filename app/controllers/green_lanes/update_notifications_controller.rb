module GreenLanes
  class UpdateNotificationsController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @updates = GreenLanes::UpdateNotification.all(page: current_page).fetch
    end

    def edit
      @update = GreenLanes::UpdateNotification.find(params[:id])
    end

    def update
      @update = GreenLanes::UpdateNotification.find(params[:id])

      if @update.valid? && @update.save
        redirect_to green_lanes_update_notifications_path, notice: 'Notification updated'
      else
        render :edit
      end
    end
  end
end
