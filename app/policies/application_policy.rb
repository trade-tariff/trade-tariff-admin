# Base policy class with deny-by-default
# All policies should inherit from this or follow the same pattern
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Deny by default - all actions return false unless explicitly allowed
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  # Helper methods for role checks
  def technical_operator?
    user&.technical_operator? || false
  end

  def hmrc_admin?
    user&.hmrc_admin? || false
  end

  def auditor?
    user&.auditor? || false
  end

  def guest?
    user&.guest? || false
  end

  # Helper to check if user can access XI services
  def can_access_xi?
    technical_operator? || auditor?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

  private

    attr_reader :user, :scope
  end
end
