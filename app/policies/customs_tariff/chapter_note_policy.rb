module CustomsTariff
  class ChapterNotePolicy < ApplicationPolicy
    def create?  = technical_operator?
    def edit?    = technical_operator?
    def update?  = technical_operator?
    def destroy? = technical_operator?
  end
end
