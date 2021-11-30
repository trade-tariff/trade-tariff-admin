class GovspeakController < AuthenticatedController
  def govspeak
    # Keeps either the entire current flash or a specific flash entry
    # available for the next action
    flash.keep

    if params[:govspeak]
      substituted_content = helpers.replace_service_tags(params[:govspeak].to_s)
      doc = Govspeak::Document.new(substituted_content, sanitize: true)

      respond_to do |format|
        format.json { render json: { govspeak: doc.to_html } }
      end
    else
      render nothing: true, status: :no_content
    end
  end
end
