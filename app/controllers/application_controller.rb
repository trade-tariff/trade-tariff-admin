class ApplicationController < ActionController::Base
  delegate :govuk_frontend?, to: TradeTariffAdmin

  before_action if: :govuk_frontend? do
    request.variant = :govuk
  end
end
