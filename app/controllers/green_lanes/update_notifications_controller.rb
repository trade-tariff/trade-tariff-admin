module GreenLanes
  class UpdateNotificationsController < AuthenticatedController
    include XiOnly

    def index
      @updates = GreenLanes::UpdateNotification.all(page: current_page)
    end

    def edit
      @update = GreenLanes::UpdateNotification.find(params[:id])
    end

    # TODO: This actually does nothing as far as I can make out since no changes are taking place
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
