class GovspeakController < AuthenticatedController
  def govspeak
    # Keeps either the entire current flash or a specific flash entry
    # available for the next action
    flash.keep

    if params[:govspeak]
      @preview = GovspeakPreview.new(params[:govspeak])

      respond_to do |format|
        format.json { render json: { govspeak: @preview.render } }
      end
    else
      render nothing: true, status: :no_content
    end
  end
end
