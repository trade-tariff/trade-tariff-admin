class CspReportsController < ApplicationController
  skip_forgery_protection only: %i[create]

  def create
    Rails.logger.warn "CSP Violation: #{request.body.read}"
    # Potentially, send an error message to new relic
    head :ok
  end
end
