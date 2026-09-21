class VersionPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end
end
