module GreenLanes
  class UpdateNotificationsController < AuthenticatedController
    include XiOnly

    def index
      authorize GreenLanes::UpdateNotification, :index?
      @updates = GreenLanes::UpdateNotification.all(page: current_page)
    end

    def edit
      @update = GreenLanes::UpdateNotification.find(params[:id])
      authorize @update, :update?
    end

    # Backend will update the notification status to inactive
    def update
      @update = GreenLanes::UpdateNotification.find(params[:id])
      authorize @update, :update?

      if @update.save
        redirect_to green_lanes_update_notifications_path, notice: "Notification updated"
      else
        render :edit
      end
    end
  end
end
