module Notes
  module Sections
    class SectionNotesController < AuthenticatedController
      before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

      def new
        @section_note = SectionNote.new
      end

      def create
        @section_note = section.section_note.build(section_note_create_params.to_h)

        if @section_note.valid? && @section_note.save
          redirect_to index_url, notice: 'Section note was successfully created.'
        else
          render :new
        end
      end

      def edit
        @section_note = section.section_note.reload
      end

      def update
        @section_note = section.section_note.reload
        @section_note.assign_attributes(section_note_update_params.to_h)

        if @section_note.valid? && @section_note.save
          redirect_to index_url, notice: 'Section note was successfully updated.'
        else
          render :edit
        end
      end

      def destroy
        @section_note = section.section_note.reload
        @section_note.destroy

        redirect_to index_url, notice: 'Section note was successfully removed.'
      end

      private

      def section
        @section ||= Section.find(params[:section_id])
      end
      helper_method :section

      def authorize_user
        authorize SectionNote, :edit?
      end

      def section_note_create_params
        params.require(:section_note).permit(:content, :section_id)
      end

      def section_note_update_params
        params.require(:section_note).permit(:content).merge(section_id: section.id)
      end
    end
  end
end
