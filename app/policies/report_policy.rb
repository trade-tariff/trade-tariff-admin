class ReportPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def run?
    technical_operator?
  end

  def send_email?
    technical_operator?
  end
end
