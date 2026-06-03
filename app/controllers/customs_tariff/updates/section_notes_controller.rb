module CustomsTariff
  module Updates
    class SectionNotesController < AuthenticatedController
      def edit
        @update = CustomsTariff::Update.find(params[:update_version])
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @section_note, :edit?
      end

      def update
        @update = CustomsTariff::Update.find(params[:update_version])
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @section_note, :update?
        @section_note.build(content: section_note_params[:content])

        if @section_note.save && @section_note.errors.empty?
          redirect_to customs_tariff_update_path(params[:update_version]),
                      notice: "Section note updated."
        else
          render :edit
        end
      end

      def preview
        authorize CustomsTariff::SectionNote, :update?
        content = params.fetch(:content, "")
        formatted = TariffNoteFormatter.new(content).format
        render json: { html: GovspeakPreview.new(formatted).render }
      end

    private

      def section_note_params
        params.require(:customs_tariff_section_note).permit(:content)
      end
    end
  end
end
