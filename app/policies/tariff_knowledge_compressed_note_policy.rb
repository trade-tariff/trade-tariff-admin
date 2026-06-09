# UK Service - TariffKnowledgeCompressedNote: TECHNICAL_OPERATOR only
class TariffKnowledgeCompressedNotePolicy < ApplicationPolicy
  def index?
    technical_operator?
  end

  def show?
    technical_operator?
  end

  def update?
    technical_operator?
  end
end
