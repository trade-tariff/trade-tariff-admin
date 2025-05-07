class HealthcheckController < ApplicationController
  def check
    User.first # test db connectivity
    render json: { git_sha1: TradeTariffAdmin.revision }
  end
end
