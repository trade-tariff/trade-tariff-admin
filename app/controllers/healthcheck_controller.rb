class HealthcheckController < ApplicationController
  def check
    User.first # test db connectivity
    render json: { git_sha1: CURRENT_REVISION }
  end

  def checkz
    render json: { git_sha1: CURRENT_REVISION }
  end
end
