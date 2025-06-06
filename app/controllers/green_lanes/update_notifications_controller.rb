module GreenLanes
  class UpdateNotificationsController < AuthenticatedController
    include XiOnly

    def index
      @updates = GreenLanes::UpdateNotification.all(page: current_page)
    end

    def edit
      @update = GreenLanes::UpdateNotification.find(params[:id])
    end

    # Backend will update the notification status to inactive
    def update
      @update = GreenLanes::UpdateNotification.find(params[:id])

      if @update.save
        redirect_to green_lanes_update_notifications_path, notice: 'Notification updated'
      else
        render :edit
      end
    end
  end
end
