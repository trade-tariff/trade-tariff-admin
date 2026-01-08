# Sections & Chapters: TECHNICAL_OPERATOR full control, HMRC_ADMIN hidden, AUDITOR read-only, GUEST hidden
class SectionNotePolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  def create?
    technical_operator?
  end

  def update?
    technical_operator?
  end

  def destroy?
    technical_operator?
  end
end
