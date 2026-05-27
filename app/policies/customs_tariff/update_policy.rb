module CustomsTariff
  class UpdatePolicy < ApplicationPolicy
    def index?  = technical_operator? || auditor?
    def show?   = technical_operator? || auditor?
    def update? = technical_operator?
  end
end
