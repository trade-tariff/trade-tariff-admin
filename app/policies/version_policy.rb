class VersionPolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def restore?
    technical_operator?
  end
end
