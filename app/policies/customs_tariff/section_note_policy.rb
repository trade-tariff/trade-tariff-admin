module CustomsTariff
  class SectionNotePolicy < ApplicationPolicy
    def edit?   = technical_operator?
    def update? = technical_operator?
  end
end
