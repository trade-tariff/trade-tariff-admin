module PunditAuthorization
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError do |e|
      render "authorisations/unauthorised", layout: "unauthorised", status: :forbidden, locals: { message: e.message }
    end
  end
end
