module Notes
  module Sections
    class SectionNotesController < AuthenticatedController
      def new
        authorize SectionNote, :create?
        @section_note = SectionNote.new
      end

      def create
        authorize SectionNote, :create?
        @section_note = section.section_note.build(section_note_create_params.to_h.merge(section_id: section.id))

        if @section_note.valid? && @section_note.save
          redirect_to index_url, notice: "Section note was successfully created."
        else
          render :new
        end
      end

      def edit
        @section_note = section.section_note
        authorize @section_note, :update?
      end

      def update
        @section_note = section.section_note
        authorize @section_note, :update?
        @section_note.build(section_note_update_params.to_h)

        if @section_note.valid? && @section_note.save
          redirect_to index_url, notice: "Section note was successfully updated."
        else
          render :edit
        end
      end

      def destroy
        @section_note = section.section_note
        authorize @section_note, :destroy?
        @section_note.destroy

        redirect_to index_url, notice: "Section note was successfully removed."
      end

    private

      def section
        @section ||= Section.find(params[:section_id])
      end
      helper_method :section

      def section_note_create_params
        params.require(:section_note).permit(:content, :section_id)
      end

      def section_note_update_params
        params.require(:section_note).permit(:content).merge(section_id: section.id)
      end
    end
  end
end
