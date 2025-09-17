class ErrorsController < ApplicationController
  before_action :disable_service_switching!

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Resource not found" }, status: :not_found }
      format.all { render status: :not_found, plain: "Resource not found" }
    end
  end

  def unprocessable_content
    message = "We're sorry, but we cannot process your request at this time.<br>
                 Please contact support for assistance or try a different request.".html_safe

    respond_to do |format|
      format.html { render "error", status: :unprocessable_content, locals: { header: "Unprocessable entity", message: } }
      format.json { render json: { error: "Unprocessable entity" }, status: :unprocessable_content }
      format.all { render status: :unprocessable_content, plain: "Unprocessable entity" }
    end
  end

  def internal_server_error
    message = "We are experiencing technical difficulties"

    respond_to do |format|
      format.html { render "error", status: :internal_server_error, locals: { header: "We are experiencing technical difficulties", message: } }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.all { render status: :internal_server_error, plain: "Internal server error" }
    end
  end

  def bad_request
    message = "The request you made is not valid.<br>
                 Please contact support for assistance or try a different request.".html_safe

    respond_to do |format|
      format.html { render "error", status: :bad_request, locals: { header: "Bad request", message: } }
      format.json { render json: { error: "Bad request" }, status: :bad_request }
      format.all { render status: :bad_request, plain: "Bad request" }
    end
  end

  def method_not_allowed
    message = "We're sorry, but this request method is not supported.<br>
                 Please contact support for assistance or try a different request.".html_safe

    respond_to do |format|
      format.html { render "error", status: :method_not_allowed, locals: { header: "Method not allowed", message: } }
      format.json { render json: { error: "Method not allowed" }, status: :method_not_allowed }
      format.all { render status: :method_not_allowed, plain: "Method not allowed" }
    end
  end

  def not_acceptable
    message = "Unfortunately, we cannot fulfill your request as it is not in a format we can accept.<br>
                 Please contact support for assistance or try a different request.".html_safe

    respond_to do |format|
      format.html { render "error", status: :not_acceptable, locals: { header: "Not acceptable", message: } }
      format.json { render json: { error: "Not acceptable" }, status: :not_acceptable }
      format.all { render status: :not_acceptable, plain: "Not acceptable" }
    end
  end

  def not_implemented
    message = 'We\'re sorry, but the requested action is not supported by our server at this time.<br>
                 Please contact support for assistance or try a different request.'.html_safe

    respond_to do |format|
      format.html { render "error", status: :not_implemented, locals: { header: "Not implemented", message: } }
      format.json { render json: { error: "Not implemented" }, status: :not_implemented }
      format.all { render status: :not_implemented, plain: "Not implemented" }
    end
  end
end
