module PunditAuthorization
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError do |e|
      respond_to do |format|
        format.html { render "authorisations/unauthorised", layout: "unauthorised", status: :forbidden, locals: { message: e.message } }
        format.json { render json: { error: e.message }, status: :forbidden }
        format.any { render plain: e.message, status: :forbidden }
      end
    end
  end
end
